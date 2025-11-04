(define-data-var owner (optional principal) none)

(define-map flags
  { key: (string-ascii 32) }
  { value: bool }
)
(define-map numbers
  { key: (string-ascii 32) }
  { value: uint }
)
(define-map addresses
  { key: (string-ascii 32) }
  { value: principal }
)

(define-constant err-owner-not-set u100)
(define-constant err-unauthorized u101)
(define-constant err-owner-already-set u102)

(define-private (ensure-owner)
  (match (var-get owner)
    o (if (is-eq o tx-sender)
      (ok true)
      (err err-unauthorized)
    )
    (err err-owner-not-set)
  )
)

(define-public (init (new-owner principal))
  (if (is-some (var-get owner))
    (err err-owner-already-set)
    (begin
      (var-set owner (some new-owner))
      (ok true)
    )
  )
)

(define-read-only (get-owner)
  (var-get owner)
)

(define-public (set-flag
    (name (string-ascii 32))
    (value bool)
  )
  (match (ensure-owner)
    success (begin
      (map-set flags { key: name } { value: value })
      (ok true)
    )
    error-val (err error-val)
  )
)

(define-public (set-number
    (name (string-ascii 32))
    (value uint)
  )
  (match (ensure-owner)
    success (begin
      (map-set numbers { key: name } { value: value })
      (ok true)
    )
    error-val (err error-val)
  )
)

(define-public (set-address
    (name (string-ascii 32))
    (value principal)
  )
  (match (ensure-owner)
    success (begin
      (map-set addresses { key: name } { value: value })
      (ok true)
    )
    error-val (err error-val)
  )
)

(define-read-only (get-flag (name (string-ascii 32)))
  (match (map-get? flags { key: name })
    v (get value v)
    false
  )
)

(define-read-only (get-number (name (string-ascii 32)))
  (match (map-get? numbers { key: name })
    v (get value v)
    u0
  )
)

(define-read-only (get-address (name (string-ascii 32)))
  (match (map-get? addresses { key: name })
    v (get value v)
    tx-sender
  )
)

(define-public (pause)
  (match (ensure-owner)
    success (begin
      (map-set flags { key: "paused" } { value: true })
      (ok true)
    )
    error-val (err error-val)
  )
)

(define-public (unpause)
  (match (ensure-owner)
    success (begin
      (map-set flags { key: "paused" } { value: false })
      (ok true)
    )
    error-val (err error-val)
  )
)

(define-read-only (is-paused)
  (match (map-get? flags { key: "paused" })
    v (get value v)
    false
  )
)
