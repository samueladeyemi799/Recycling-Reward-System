(define-constant contract-owner tx-sender)

(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-insufficient-points (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-already-exists (err u104))
(define-constant err-unauthorized (err u105))

(define-data-var next-user-id uint u1)
(define-data-var next-submission-id uint u1)
(define-data-var next-reward-id uint u1)

(define-map users
    { user-id: uint }
    {
        address: principal,
        name: (string-ascii 64),
        total-points: uint,
        recycling-count: uint,
        joined-at: uint,
    }
)

(define-map user-address-to-id
    { address: principal }
    { user-id: uint }
)

(define-map material-types
    { material-id: uint }
    {
        name: (string-ascii 32),
        points-per-unit: uint,
        active: bool,
    }
)

(define-map recycling-submissions
    { submission-id: uint }
    {
        user-id: uint,
        material-id: uint,
        quantity: uint,
        points-earned: uint,
        submitted-at: uint,
        verified: bool,
    }
)

(define-map rewards
    { reward-id: uint }
    {
        name: (string-ascii 64),
        description: (string-ascii 256),
        points-cost: uint,
        available: bool,
    }
)

(define-map user-rewards
    {
        user-id: uint,
        reward-id: uint,
    }
    {
        redeemed-at: uint,
        quantity: uint,
    }
)

(define-read-only (get-user (user-id uint))
    (map-get? users { user-id: user-id })
)

(define-read-only (get-user-by-address (address principal))
    (match (map-get? user-address-to-id { address: address })
        entry (map-get? users { user-id: (get user-id entry) })
        none
    )
)

(define-read-only (get-material-type (material-id uint))
    (map-get? material-types { material-id: material-id })
)

(define-read-only (get-submission (submission-id uint))
    (map-get? recycling-submissions { submission-id: submission-id })
)

(define-read-only (get-reward (reward-id uint))
    (map-get? rewards { reward-id: reward-id })
)

(define-read-only (get-user-reward
        (user-id uint)
        (reward-id uint)
    )
    (map-get? user-rewards {
        user-id: user-id,
        reward-id: reward-id,
    })
)

(define-read-only (get-next-user-id)
    (var-get next-user-id)
)

(define-read-only (get-next-submission-id)
    (var-get next-submission-id)
)

(define-read-only (get-next-reward-id)
    (var-get next-reward-id)
)

(define-public (register-user (name (string-ascii 64)))
    (let (
            (current-user-id (var-get next-user-id))
            (existing-user (map-get? user-address-to-id { address: tx-sender }))
        )
        (asserts! (is-none existing-user) err-already-exists)
        (map-set users { user-id: current-user-id } {
            address: tx-sender,
            name: name,
            total-points: u0,
            recycling-count: u0,
            joined-at: stacks-block-height,
        })
        (map-set user-address-to-id { address: tx-sender } { user-id: current-user-id })
        (var-set next-user-id (+ current-user-id u1))
        (ok current-user-id)
    )
)

(define-public (add-material-type
        (name (string-ascii 32))
        (points-per-unit uint)
    )
    (let ((material-id (var-get next-submission-id)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> points-per-unit u0) err-invalid-amount)
        (map-set material-types { material-id: material-id } {
            name: name,
            points-per-unit: points-per-unit,
            active: true,
        })
        (ok material-id)
    )
)

(define-public (toggle-material-type (material-id uint))
    (let ((material (unwrap! (map-get? material-types { material-id: material-id })
            err-not-found
        )))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set material-types { material-id: material-id }
            (merge material { active: (not (get active material)) })
        )
        (ok true)
    )
)

(define-public (submit-recycling
        (material-id uint)
        (quantity uint)
    )
    (let (
            (user-lookup (unwrap! (map-get? user-address-to-id { address: tx-sender })
                err-not-found
            ))
            (user-id (get user-id user-lookup))
            (user (unwrap! (map-get? users { user-id: user-id }) err-not-found))
            (material (unwrap! (map-get? material-types { material-id: material-id })
                err-not-found
            ))
            (submission-id (var-get next-submission-id))
            (points-earned (* quantity (get points-per-unit material)))
        )
        (asserts! (get active material) err-not-found)
        (asserts! (> quantity u0) err-invalid-amount)
        (map-set recycling-submissions { submission-id: submission-id } {
            user-id: user-id,
            material-id: material-id,
            quantity: quantity,
            points-earned: points-earned,
            submitted-at: stacks-block-height,
            verified: false,
        })
        (var-set next-submission-id (+ submission-id u1))
        (ok submission-id)
    )
)

(define-public (verify-submission (submission-id uint))
    (let (
            (submission (unwrap!
                (map-get? recycling-submissions { submission-id: submission-id })
                err-not-found
            ))
            (user-id (get user-id submission))
            (user (unwrap! (map-get? users { user-id: user-id }) err-not-found))
            (points-to-add (get points-earned submission))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (not (get verified submission)) err-already-exists)
        (map-set recycling-submissions { submission-id: submission-id }
            (merge submission { verified: true })
        )
        (map-set users { user-id: user-id }
            (merge user {
                total-points: (+ (get total-points user) points-to-add),
                recycling-count: (+ (get recycling-count user) u1),
            })
        )
        (ok true)
    )
)

(define-public (add-reward
        (name (string-ascii 64))
        (description (string-ascii 256))
        (points-cost uint)
    )
    (let ((reward-id (var-get next-reward-id)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> points-cost u0) err-invalid-amount)
        (map-set rewards { reward-id: reward-id } {
            name: name,
            description: description,
            points-cost: points-cost,
            available: true,
        })
        (var-set next-reward-id (+ reward-id u1))
        (ok reward-id)
    )
)

(define-public (toggle-reward (reward-id uint))
    (let ((reward (unwrap! (map-get? rewards { reward-id: reward-id }) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set rewards { reward-id: reward-id }
            (merge reward { available: (not (get available reward)) })
        )
        (ok true)
    )
)

(define-public (redeem-reward
        (reward-id uint)
        (quantity uint)
    )
    (let (
            (user-lookup (unwrap! (map-get? user-address-to-id { address: tx-sender })
                err-not-found
            ))
            (user-id (get user-id user-lookup))
            (user (unwrap! (map-get? users { user-id: user-id }) err-not-found))
            (reward (unwrap! (map-get? rewards { reward-id: reward-id }) err-not-found))
            (total-cost (* (get points-cost reward) quantity))
            (existing-redemption (map-get? user-rewards {
                user-id: user-id,
                reward-id: reward-id,
            }))
        )
        (asserts! (get available reward) err-not-found)
        (asserts! (> quantity u0) err-invalid-amount)
        (asserts! (>= (get total-points user) total-cost) err-insufficient-points)
        (map-set users { user-id: user-id }
            (merge user { total-points: (- (get total-points user) total-cost) })
        )
        (match existing-redemption
            redemption (map-set user-rewards {
                user-id: user-id,
                reward-id: reward-id,
            } {
                redeemed-at: stacks-block-height,
                quantity: (+ (get quantity redemption) quantity),
            })
            (map-set user-rewards {
                user-id: user-id,
                reward-id: reward-id,
            } {
                redeemed-at: stacks-block-height,
                quantity: quantity,
            })
        )
        (ok true)
    )
)

(define-read-only (get-user-stats (user-id uint))
    (match (map-get? users { user-id: user-id })
        user (some {
            total-points: (get total-points user),
            recycling-count: (get recycling-count user),
            joined-at: (get joined-at user),
        })
        none
    )
)

(define-read-only (calculate-points
        (material-id uint)
        (quantity uint)
    )
    (match (map-get? material-types { material-id: material-id })
        material (ok (* quantity (get points-per-unit material)))
        (err err-not-found)
    )
)
