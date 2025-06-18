;; Bottleneck Identification Contract
;; Identifies process bottlenecks and constraints

(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_BOTTLENECK_NOT_FOUND (err u401))
(define-constant ERR_INVALID_SEVERITY (err u402))

;; Data structures
(define-map bottlenecks uint {
    process-id: uint,
    step-id: uint,
    identified-by: principal,
    severity: uint,
    description: (string-ascii 500),
    impact-score: uint,
    identified-at: uint,
    status: (string-ascii 20),
    resolution-priority: uint
})

(define-map bottleneck-resolutions uint {
    bottleneck-id: uint,
    proposed-solution: (string-ascii 500),
    estimated-impact: uint,
    implementation-cost: uint,
    timeline: uint,
    proposed-by: principal
})

(define-data-var next-bottleneck-id uint u1)

;; Read-only functions
(define-read-only (get-bottleneck (bottleneck-id uint))
    (map-get? bottlenecks bottleneck-id)
)

(define-read-only (get-bottleneck-resolution (bottleneck-id uint))
    (map-get? bottleneck-resolutions bottleneck-id)
)

(define-read-only (calculate-priority-score (severity uint) (impact-score uint))
    (* severity impact-score)
)

;; Public functions
(define-public (identify-bottleneck
    (process-id uint)
    (step-id uint)
    (severity uint)
    (description (string-ascii 500))
    (impact-score uint))
    (let ((bottleneck-id (var-get next-bottleneck-id)))
        (asserts! (and (>= severity u1) (<= severity u10)) ERR_INVALID_SEVERITY)
        (asserts! (and (>= impact-score u1) (<= impact-score u100)) ERR_INVALID_SEVERITY)

        (map-set bottlenecks bottleneck-id {
            process-id: process-id,
            step-id: step-id,
            identified-by: tx-sender,
            severity: severity,
            description: description,
            impact-score: impact-score,
            identified-at: block-height,
            status: "identified",
            resolution-priority: (calculate-priority-score severity impact-score)
        })

        (var-set next-bottleneck-id (+ bottleneck-id u1))
        (ok bottleneck-id)
    )
)

(define-public (propose-resolution
    (bottleneck-id uint)
    (proposed-solution (string-ascii 500))
    (estimated-impact uint)
    (implementation-cost uint)
    (timeline uint))
    (let ((bottleneck (unwrap! (get-bottleneck bottleneck-id) ERR_BOTTLENECK_NOT_FOUND)))
        (map-set bottleneck-resolutions bottleneck-id {
            bottleneck-id: bottleneck-id,
            proposed-solution: proposed-solution,
            estimated-impact: estimated-impact,
            implementation-cost: implementation-cost,
            timeline: timeline,
            proposed-by: tx-sender
        })

        (map-set bottlenecks bottleneck-id
            (merge bottleneck { status: "resolution-proposed" })
        )
        (ok true)
    )
)

(define-public (update-bottleneck-status (bottleneck-id uint) (status (string-ascii 20)))
    (let ((bottleneck (unwrap! (get-bottleneck bottleneck-id) ERR_BOTTLENECK_NOT_FOUND)))
        (map-set bottlenecks bottleneck-id
            (merge bottleneck { status: status })
        )
        (ok true)
    )
)
