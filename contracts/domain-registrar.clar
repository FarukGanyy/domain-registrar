;; ------------------------------------------------------------
;; Domain Registrar Smart Contract
;; Description: Register, renew, and transfer domains on-chain.
;; ------------------------------------------------------------

(define-constant ERR_ALREADY_REGISTERED (err u100))
(define-constant ERR_NOT_REGISTERED     (err u101))
(define-constant ERR_NOT_OWNER          (err u102))
(define-constant ERR_EXPIRED            (err u103))
(define-constant ERR_LOW_PAYMENT        (err u104))
(define-constant ERR_TRANSFER_FAILED    (err u105))

(define-data-var admin (optional principal) none)
(define-data-var base-price uint u1000000) ;; 1 STX (1_000_000 microSTX)
(define-data-var registration-period uint u525600) ;; ~1 year in blocks

;; ------------------------------------------------------------
;; Domain structure
;; ------------------------------------------------------------
(define-map domains
  { name: (string-ascii 48) }
  {
    owner: principal,
    expiry: uint,
    price: uint
  }
)

;; ------------------------------------------------------------
;; Register a new domain
;; ------------------------------------------------------------
(define-public (register (name (string-ascii 48)) (payment uint) (current-block uint))
  (begin
    (asserts! (is-none (map-get? domains { name: name })) ERR_ALREADY_REGISTERED)
    (let ((price (var-get base-price)))
      (asserts! (>= payment price) ERR_LOW_PAYMENT)
      (map-set domains
        { name: name }
        {
          owner: tx-sender,
          expiry: (+ current-block (var-get registration-period)),
          price: price
        }
      )
  (ok (tuple (domain name) (owner tx-sender) (expiry (+ current-block (var-get registration-period))) (paid payment)))
    )
  )
)

;; ------------------------------------------------------------
;; Renew existing domain
;; ------------------------------------------------------------
(define-public (renew (name (string-ascii 48)) (payment uint) (current-block uint))
  (match (map-get? domains { name: name })
    domain
      (begin
        (asserts! (is-eq (get owner domain) tx-sender) ERR_NOT_OWNER)
        (asserts! (>= payment (get price domain)) ERR_LOW_PAYMENT)
  (let ((new-expiry (+ (get expiry domain) (var-get registration-period))))
          (map-set domains
            { name: name }
            {
              owner: (get owner domain),
              expiry: new-expiry,
              price: (get price domain)
            }
          )
          (ok (tuple (domain name) (renewed-until new-expiry) (paid payment)))
        )
      )
    ERR_NOT_REGISTERED
  )
)

;; ------------------------------------------------------------
;; Transfer domain to another user
;; ------------------------------------------------------------
(define-public (transfer-domain (name (string-ascii 48)) (new-owner principal) (current-block uint))
  (match (map-get? domains { name: name })
    domain
      (begin
        (asserts! (is-eq (get owner domain) tx-sender) ERR_NOT_OWNER)
        (asserts! (> (get expiry domain) current-block) ERR_EXPIRED)
        (map-set domains
          { name: name }
          {
            owner: new-owner,
            expiry: (get expiry domain),
            price: (get price domain)
          }
        )
        (ok (tuple (domain name) (new-owner new-owner)))
      )
    ERR_NOT_REGISTERED
  )
)

;; ------------------------------------------------------------
;; Admin: Update base price
;; ------------------------------------------------------------
(define-public (update-base-price (new-price uint))
  (begin
    (match (var-get admin)
      admin-pr
        (begin
          (asserts! (is-eq tx-sender admin-pr) ERR_NOT_OWNER)
          (var-set base-price new-price)
          (ok (tuple (updated-price new-price)))
        )
      ERR_NOT_OWNER
    )
  )
)

;; ------------------------------------------------------------
;; Read-only views
;; ------------------------------------------------------------
(define-read-only (get-domain (name (string-ascii 48)))
  (ok (map-get? domains { name: name }))
)

(define-read-only (get-base-price)
  (ok (var-get base-price))
)

(define-read-only (is-available (name (string-ascii 48)) (current-block uint))
  (match (map-get? domains { name: name })
    domain
      (ok (< current-block (get expiry domain)))
    (ok true)
  )
)
