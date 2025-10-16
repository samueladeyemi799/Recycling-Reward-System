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
(define-data-var next-competition-id uint u1)
(define-data-var current-week uint u1)

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

(define-map weekly-leaderboard
    {
        week: uint,
        rank: uint,
    }
    {
        user-id: uint,
        points: uint,
        recycling-count: uint,
    }
)

(define-map user-weekly-stats
    {
        user-id: uint,
        week: uint,
    }
    {
        weekly-points: uint,
        weekly-count: uint,
    }
)

(define-map competitions
    { competition-id: uint }
    {
        name: (string-ascii 64),
        description: (string-ascii 256),
        start-week: uint,
        end-week: uint,
        bonus-multiplier: uint,
        active: bool,
        winner-reward: uint,
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

(define-read-only (get-current-week)
    (var-get current-week)
)

(define-read-only (get-weekly-leaderboard
        (week uint)
        (rank uint)
    )
    (map-get? weekly-leaderboard {
        week: week,
        rank: rank,
    })
)

(define-read-only (get-user-weekly-stats
        (user-id uint)
        (week uint)
    )
    (map-get? user-weekly-stats {
        user-id: user-id,
        week: week,
    })
)

(define-read-only (get-competition (competition-id uint))
    (map-get? competitions { competition-id: competition-id })
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

;; Community Impact Tracker - Independent feature for environmental metrics
(define-constant err-milestone-not-found (err u106))
(define-constant err-invalid-category (err u107))
(define-constant err-milestone-already-achieved (err u108))

(define-data-var next-milestone-id uint u1)
(define-data-var total-co2-saved uint u0)
(define-data-var total-waste-diverted uint u0)
(define-data-var total-water-saved uint u0)
(define-data-var total-energy-saved uint u0)

;; Environmental impact categories
(define-constant CATEGORY-CO2 u1)
(define-constant CATEGORY-WASTE u2)
(define-constant CATEGORY-WATER u3)
(define-constant CATEGORY-ENERGY u4)

;; Material environmental impact factors per unit
(define-map material-impact-factors
    { material-id: uint }
    {
        co2-saved-per-unit: uint,     ;; grams of CO2 saved
        waste-diverted-per-unit: uint, ;; grams of waste diverted
        water-saved-per-unit: uint,    ;; ml of water saved
        energy-saved-per-unit: uint,   ;; watts saved
    }
)

;; Community milestones for collective achievements
(define-map community-milestones
    { milestone-id: uint }
    {
        name: (string-ascii 64),
        description: (string-ascii 256),
        category: uint,               ;; 1=CO2, 2=Waste, 3=Water, 4=Energy
        target-amount: uint,
        current-amount: uint,
        achieved: bool,
        achieved-at: (optional uint),
        reward-points: uint,          ;; Bonus points when milestone reached
    }
)

;; User impact contributions
(define-map user-impact-contributions
    { user-id: uint }
    {
        total-co2-saved: uint,
        total-waste-diverted: uint,
        total-water-saved: uint,
        total-energy-saved: uint,
        milestones-contributed: uint,
    }
)

;; Individual user environmental badges
(define-map user-badges
    {
        user-id: uint,
        badge-type: uint,
    }
    {
        earned-at: uint,
        level: uint,
    }
)

;; Badge thresholds (level 1, 2, 3 requirements)
(define-constant BADGE-ECO-WARRIOR u1)      ;; CO2 savings
(define-constant BADGE-WASTE-REDUCER u2)    ;; Waste diverted
(define-constant BADGE-WATER-GUARDIAN u3)   ;; Water saved
(define-constant BADGE-ENERGY-SAVER u4)     ;; Energy conserved

;; Read-only functions
(define-read-only (get-community-impact)
    {
        total-co2-saved: (var-get total-co2-saved),
        total-waste-diverted: (var-get total-waste-diverted),
        total-water-saved: (var-get total-water-saved),
        total-energy-saved: (var-get total-energy-saved),
    }
)

(define-read-only (get-material-impact-factors (material-id uint))
    (map-get? material-impact-factors { material-id: material-id })
)

(define-read-only (get-community-milestone (milestone-id uint))
    (map-get? community-milestones { milestone-id: milestone-id })
)

(define-read-only (get-user-impact-contribution (user-id uint))
    (map-get? user-impact-contributions { user-id: user-id })
)

(define-read-only (get-user-badge (user-id uint) (badge-type uint))
    (map-get? user-badges {
        user-id: user-id,
        badge-type: badge-type,
    })
)

;; Public functions for contract owner
(define-public (set-material-impact-factors
        (material-id uint)
        (co2-saved uint)
        (waste-diverted uint)
        (water-saved uint)
        (energy-saved uint)
    )
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set material-impact-factors { material-id: material-id } {
            co2-saved-per-unit: co2-saved,
            waste-diverted-per-unit: waste-diverted,
            water-saved-per-unit: water-saved,
            energy-saved-per-unit: energy-saved,
        })
        (ok true)
    )
)

(define-public (create-community-milestone
        (name (string-ascii 64))
        (description (string-ascii 256))
        (category uint)
        (target-amount uint)
        (reward-points uint)
    )
    (let ((milestone-id (var-get next-milestone-id)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (and (>= category u1) (<= category u4)) err-invalid-category)
        (asserts! (> target-amount u0) err-invalid-amount)
        (map-set community-milestones { milestone-id: milestone-id } {
            name: name,
            description: description,
            category: category,
            target-amount: target-amount,
            current-amount: u0,
            achieved: false,
            achieved-at: none,
            reward-points: reward-points,
        })
        (var-set next-milestone-id (+ milestone-id u1))
        (ok milestone-id)
    )
)

;; Public function to calculate and update environmental impact after recycling
(define-public (update-environmental-impact
        (user-id uint)
        (material-id uint)
        (quantity uint)
    )
    (let (
            (impact-factors (unwrap! (map-get? material-impact-factors { material-id: material-id })
                (ok false) ;; No impact factors set, skip update
            ))
            (co2-impact (* quantity (get co2-saved-per-unit impact-factors)))
            (waste-impact (* quantity (get waste-diverted-per-unit impact-factors)))
            (water-impact (* quantity (get water-saved-per-unit impact-factors)))
            (energy-impact (* quantity (get energy-saved-per-unit impact-factors)))
            (existing-contribution (default-to {
                total-co2-saved: u0,
                total-waste-diverted: u0,
                total-water-saved: u0,
                total-energy-saved: u0,
                milestones-contributed: u0,
            } (map-get? user-impact-contributions { user-id: user-id })))
        )
        ;; Update global impact totals
        (var-set total-co2-saved (+ (var-get total-co2-saved) co2-impact))
        (var-set total-waste-diverted (+ (var-get total-waste-diverted) waste-impact))
        (var-set total-water-saved (+ (var-get total-water-saved) water-impact))
        (var-set total-energy-saved (+ (var-get total-energy-saved) energy-impact))
        
        ;; Update user impact contributions
        (map-set user-impact-contributions { user-id: user-id } {
            total-co2-saved: (+ (get total-co2-saved existing-contribution) co2-impact),
            total-waste-diverted: (+ (get total-waste-diverted existing-contribution) waste-impact),
            total-water-saved: (+ (get total-water-saved existing-contribution) water-impact),
            total-energy-saved: (+ (get total-energy-saved existing-contribution) energy-impact),
            milestones-contributed: (get milestones-contributed existing-contribution),
        })
        
        ;; Check and award user badges
        (unwrap-panic (check-and-award-badges user-id))
        
        (ok true)
    )
)

;; Private function to check milestone progress and award completion
(define-private (check-milestone-completion (milestone-id uint))
    (let (
            (milestone (unwrap! (map-get? community-milestones { milestone-id: milestone-id })
                (ok false)
            ))
            (category (get category milestone))
            (target (get target-amount milestone))
            (current-global-amount (if (is-eq category CATEGORY-CO2)
                (var-get total-co2-saved)
                (if (is-eq category CATEGORY-WASTE)
                    (var-get total-waste-diverted)
                    (if (is-eq category CATEGORY-WATER)
                        (var-get total-water-saved)
                        (var-get total-energy-saved)
                    )
                )
            ))
        )
        (if (and (not (get achieved milestone)) (>= current-global-amount target))
            (begin
                (map-set community-milestones { milestone-id: milestone-id }
                    (merge milestone {
                        achieved: true,
                        achieved-at: (some stacks-block-height),
                        current-amount: current-global-amount,
                    })
                )
                (ok true)
            )
            (begin
                (map-set community-milestones { milestone-id: milestone-id }
                    (merge milestone { current-amount: current-global-amount })
                )
                (ok false)
            )
        )
    )
)

;; Private function to check and award environmental badges
(define-private (check-and-award-badges (user-id uint))
    (let (
            (user-contribution (unwrap! (map-get? user-impact-contributions { user-id: user-id })
                (ok false)
            ))
            (co2-saved (get total-co2-saved user-contribution))
            (waste-diverted (get total-waste-diverted user-contribution))
            (water-saved (get total-water-saved user-contribution))
            (energy-saved (get total-energy-saved user-contribution))
        )
        ;; Award badges based on thresholds
        (unwrap-panic (award-badge-if-eligible user-id BADGE-ECO-WARRIOR co2-saved u1000 u5000 u20000))
        (unwrap-panic (award-badge-if-eligible user-id BADGE-WASTE-REDUCER waste-diverted u500 u2500 u10000))
        (unwrap-panic (award-badge-if-eligible user-id BADGE-WATER-GUARDIAN water-saved u2000 u10000 u50000))
        (unwrap-panic (award-badge-if-eligible user-id BADGE-ENERGY-SAVER energy-saved u100 u500 u2000))
        (ok true)
    )
)

;; Helper function to award badges based on achievement levels
(define-private (award-badge-if-eligible
        (user-id uint)
        (badge-type uint)
        (amount uint)
        (level1-threshold uint)
        (level2-threshold uint)
        (level3-threshold uint)
    )
    (let (
            (existing-badge (map-get? user-badges {
                user-id: user-id,
                badge-type: badge-type,
            }))
            (new-level (if (>= amount level3-threshold) u3
                (if (>= amount level2-threshold) u2
                    (if (>= amount level1-threshold) u1 u0)
                )
            ))
        )
        (if (and (> new-level u0)
                (or (is-none existing-badge)
                    (< (get level (unwrap-panic existing-badge)) new-level)
                )
            )
            (begin
                (map-set user-badges {
                    user-id: user-id,
                    badge-type: badge-type,
                } {
                    earned-at: stacks-block-height,
                    level: new-level,
                })
                (ok true)
            )
            (ok false)
        )
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
        (unwrap-panic (update-weekly-stats user-id points-to-add))
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

(define-private (update-weekly-stats
        (user-id uint)
        (points uint)
    )
    (let (
            (current-week-val (var-get current-week))
            (existing-stats (map-get? user-weekly-stats {
                user-id: user-id,
                week: current-week-val,
            }))
        )
        (match existing-stats
            stats (map-set user-weekly-stats {
                user-id: user-id,
                week: current-week-val,
            } {
                weekly-points: (+ (get weekly-points stats) points),
                weekly-count: (+ (get weekly-count stats) u1),
            })
            (map-set user-weekly-stats {
                user-id: user-id,
                week: current-week-val,
            } {
                weekly-points: points,
                weekly-count: u1,
            })
        )
        (ok true)
    )
)

(define-public (advance-week)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set current-week (+ (var-get current-week) u1))
        (ok (var-get current-week))
    )
)

(define-public (update-leaderboard
        (week uint)
        (user-rankings (list 10
            {
            user-id: uint,
            points: uint,
            recycling-count: uint,
        }))
    )
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (fold update-single-leaderboard-entry user-rankings {
            week: week,
            rank: u1,
        })
        (ok true)
    )
)

(define-private (update-single-leaderboard-entry
        (entry {
            user-id: uint,
            points: uint,
            recycling-count: uint,
        })
        (context {
            week: uint,
            rank: uint,
        })
    )
    (begin
        (map-set weekly-leaderboard {
            week: (get week context),
            rank: (get rank context),
        }
            entry
        )
        {
            week: (get week context),
            rank: (+ (get rank context) u1),
        }
    )
)

(define-public (create-competition
        (name (string-ascii 64))
        (description (string-ascii 256))
        (start-week uint)
        (end-week uint)
        (bonus-multiplier uint)
        (winner-reward uint)
    )
    (let ((competition-id (var-get next-competition-id)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (< start-week end-week) err-invalid-amount)
        (asserts! (> bonus-multiplier u0) err-invalid-amount)
        (map-set competitions { competition-id: competition-id } {
            name: name,
            description: description,
            start-week: start-week,
            end-week: end-week,
            bonus-multiplier: bonus-multiplier,
            active: true,
            winner-reward: winner-reward,
        })
        (var-set next-competition-id (+ competition-id u1))
        (ok competition-id)
    )
)

(define-public (toggle-competition (competition-id uint))
    (let ((competition (unwrap! (map-get? competitions { competition-id: competition-id })
            err-not-found
        )))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set competitions { competition-id: competition-id }
            (merge competition { active: (not (get active competition)) })
        )
        (ok true)
    )
)

(define-public (award-competition-winner
        (competition-id uint)
        (winner-user-id uint)
    )
    (let (
            (competition (unwrap! (map-get? competitions { competition-id: competition-id })
                err-not-found
            ))
            (winner (unwrap! (map-get? users { user-id: winner-user-id }) err-not-found))
            (reward-points (get winner-reward competition))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (get active competition) err-not-found)
        (map-set users { user-id: winner-user-id }
            (merge winner { total-points: (+ (get total-points winner) reward-points) })
        )
        (map-set competitions { competition-id: competition-id }
            (merge competition { active: false })
        )
        (ok true)
    )
)
