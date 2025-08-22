;; ---------------------------------------------------------
;; Subscription Pass
;; - Users pay a subscription price (in micro-STX) to become active
;; - Subscription lasts `duration` blocks (configurable by owner)
;; - Renewing extends expiry from max(current-block, previous-expiry)
;; - Owner can set price/duration and withdraw collected funds
;; ---------------------------------------------------------

(define-constant ERR-NOT-OWNER (err u100))
(define-constant ERR-ALREADY_ACTIVE (err u101))
(define-constant ERR-NOT_ACTIVE (err u102))
(define-constant ERR-INSUFFICIENT (err u103))
(define-constant ERR-NO-FUNDS (err u104))

;; Owner set at deployment
(define-constant contract-owner tx-sender)

;; Configurable vars
(define-data-var price uint u1000000)       ;; default 1 STX = 1_000_000 micro-STX
(define-data-var duration uint u432000)     ;; default duration in blocks (approx 1 month ~ 432000 blocks @ ~6s) - adjust as needed

;; Accounting
(define-data-var total-collected uint u0)

;; Subscribers: user -> expiry-block
(define-map subscribers
  { user: principal }
  { expiry: uint }
)

;; Events (not supported in Clarity, lines commented out or removed)
;; (define-event subscribed (user principal) (amount uint) (new-expiry uint))
;; (define-event withdrew (to principal) (amount uint))
;; (define-event config-updated (price uint) (duration uint))

;; -------------------------
;; Owner functions
;; -------------------------

;; Set subscription price (micro-STX) and duration (blocks)
(define-public (set-config (new-price uint) (new-duration uint))
  (if (is-eq tx-sender contract-owner)
      (begin
        (asserts! (> new-price u0) (err u105))
        (asserts! (> new-duration u0) (err u106))
        (var-set price new-price)
        (var-set duration new-duration)
        ;; (emit-event config-updated { price: new-price, duration: new-duration })
        (ok true)
      )
      ERR-NOT-OWNER
  )
)

;; Withdraw funds from contract balance (owner only)
;; amount is micro-STX
(define-public (withdraw (amount uint))
  (if (is-eq tx-sender contract-owner)
      (let ((col (var-get total-collected)))
        (if (<= amount col)
            (begin
              (try! (stx-transfer? amount (as-contract tx-sender) tx-sender))
              (var-set total-collected (- col amount))
              ;; (emit-event withdrew { to: tx-sender, amount: amount })
              (ok true)
            )
            ERR-NO-FUNDS
        )
      )
      ERR-NOT-OWNER
  )
)

;; -------------------------
;; User functions
;; -------------------------

;; Subscribe or renew by sending exactly `price` micro-STX
;; If user already active, this extends their expiry further (no error)
(define-public (subscribe)
  (let (
        (p (var-get price))
        (dur (var-get duration))
        (now burn-block-height))
    (if (is-eq (stx-transfer? p tx-sender (as-contract tx-sender)) (ok true))
        (let ((rec (map-get? subscribers { user: tx-sender })))
          ;; compute base = max(now, prev-expiry)
          (let ((base (match rec 
                            value (if (>= (get expiry value) now) (get expiry value) now)
                            now)))
            (let ((new-exp (+ base dur)))
              (map-set subscribers { user: tx-sender } { expiry: new-exp })
              (var-set total-collected (+ (var-get total-collected) p))
              ;; (emit-event subscribed { user: tx-sender, amount: p, new-expiry: new-exp })
              (ok new-exp)
            )
          )
        )
        ERR-INSUFFICIENT
    )
  )
)

;; Cancel subscription (user deletes their record)
(define-public (cancel)
  (match (map-get? subscribers { user: tx-sender })
         value (begin
                 (map-delete subscribers { user: tx-sender })
                 (ok true))
         ERR-NOT_ACTIVE)
)

;; -------------------------
;; Read-only
;; -------------------------

;; Check whether a principal is currently active
(define-read-only (is-active (who principal))
  (match (map-get? subscribers { user: who })
         value (ok (>= (get expiry value) burn-block-height))
         (ok false))
)

;; Get subscriber expiry (0 if not present)
(define-read-only (get-expiry (who principal))
  (match (map-get? subscribers { user: who })
         value (ok (get expiry value))
         (ok u0))
)

;; Get config & stats
(define-read-only (get-config)
  { owner: contract-owner, price: (var-get price), duration: (var-get duration) }
)

(define-read-only (get-stats)
  { total_collected: (var-get total-collected) }
)
