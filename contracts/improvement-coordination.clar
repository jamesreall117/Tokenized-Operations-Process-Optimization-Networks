;; Improvement Coordination Contract
;; Coordinates process improvements and tracks implementation

(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_IMPROVEMENT_NOT_FOUND (err u501))
(define-constant ERR_INVALID_STATUS (err u502))

;; Data structures
(define-map improvements uint {
    title: (string-ascii 100),
    description: (string-ascii 500),
    process-id: uint,
    proposed-by: principal,
    assigned-to: principal,
    priority: uint,
    status: (string-ascii 20),
    created-at: uint,
    target-completion: uint,
    estimated-benefit: uint
})

(define-map improvement-progress uint {
    improvement-id: uint,
    progress-percentage: uint,
    last-updated: uint,
    updated-by: principal,
    notes: (string-ascii 300)
})

(define-map improvement-results uint {
    improvement-id: uint,
    actual-benefit: uint,
    implementation-cost: uint,
    completion-date: uint,
    success-rating: uint,
    lessons-learned: (string-ascii 500)
})

(define-data-var next-improvement-id uint u1)

;; Read-only functions
(define-read-only (get-improvement (improvement-id uint))
    (map-get? improvements improvement-id)
)

(define-read-only (get-improvement-progress (improvement-id uint))
    (map-get? improvement-progress improvement-id)
)

(define-read-only (get-improvement-results (improvement-id uint))
    (map-get? improvement-results improvement-id)
)

;; Public functions
(define-public (create-improvement
    (title (string-ascii 100))
    (description (string-ascii 500))
    (process-id uint)
    (assigned-to principal)
    (priority uint)
    (target-completion uint)
    (estimated-benefit uint))
    (let ((improvement-id (var-get next-improvement-id)))
        (map-set improvements improvement-id {
            title: title,
            description: description,
            process-id: process-id,
            proposed-by: tx-sender,
            assigned-to: assigned-to,
            priority: priority,
            status: "proposed",
            created-at: block-height,
            target-completion: target-completion,
            estimated-benefit: estimated-benefit
        })

        (var-set next-improvement-id (+ improvement-id u1))
        (ok improvement-id)
    )
)

(define-public (update-improvement-progress
    (improvement-id uint)
    (progress-percentage uint)
    (notes (string-ascii 300)))
    (let ((improvement (unwrap! (get-improvement improvement-id) ERR_IMPROVEMENT_NOT_FOUND)))
        (asserts! (or (is-eq tx-sender (get assigned-to improvement))
                     (is-eq tx-sender (get proposed-by improvement))) ERR_UNAUTHORIZED)
        (asserts! (<= progress-percentage u100) ERR_INVALID_STATUS)

        (map-set improvement-progress improvement-id {
            improvement-id: improvement-id,
            progress-percentage: progress-percentage,
            last-updated: block-height,
            updated-by: tx-sender,
            notes: notes
        })

        (if (is-eq progress-percentage u100)
            (map-set improvements improvement-id
                (merge improvement { status: "completed" }))
            (map-set improvements improvement-id
                (merge improvement { status: "in-progress" }))
        )
        (ok true)
    )
)

(define-public (record-improvement-results
    (improvement-id uint)
    (actual-benefit uint)
    (implementation-cost uint)
    (success-rating uint)
    (lessons-learned (string-ascii 500)))
    (let ((improvement (unwrap! (get-improvement improvement-id) ERR_IMPROVEMENT_NOT_FOUND)))
        (asserts! (or (is-eq tx-sender (get assigned-to improvement))
                     (is-eq tx-sender (get proposed-by improvement))) ERR_UNAUTHORIZED)
        (asserts! (<= success-rating u10) ERR_INVALID_STATUS)

        (map-set improvement-results improvement-id {
            improvement-id: improvement-id,
            actual-benefit: actual-benefit,
            implementation-cost: implementation-cost,
            completion-date: block-height,
            success-rating: success-rating,
            lessons-learned: lessons-learned
        })

        (map-set improvements improvement-id
            (merge improvement { status: "evaluated" })
        )
        (ok true)
    )
)

(define-public (approve-improvement (improvement-id uint))
    (let ((improvement (unwrap! (get-improvement improvement-id) ERR_IMPROVEMENT_NOT_FOUND)))
        (map-set improvements improvement-id
            (merge improvement { status: "approved" })
        )
        (ok true)
    )
)
