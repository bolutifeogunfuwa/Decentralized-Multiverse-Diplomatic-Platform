;; Multiversal Embassy Registry Contract
;; Manages embassies across different realities in the multiverse

(define-data-var admin principal tx-sender)

;; Data structure for embassies
(define-map embassies
  { embassy-id: uint }
  {
    embassy-name: (string-ascii 100),
    home-reality: (string-ascii 50),
    host-reality: (string-ascii 50),
    coordinates: (list 5 int),
    establishment-date: uint,
    ambassador: principal,
    staff-count: uint,
    status: (string-ascii 20)
  }
)

;; Embassy activities
(define-map embassy-activities
  { activity-id: uint }
  {
    embassy-id: uint,
    activity-type: (string-ascii 50),
    activity-description: (string-ascii 200),
    participants: (list 5 principal),
    timestamp: uint,
    outcome: (string-ascii 100)
  }
)

;; Counter for embassy IDs
(define-data-var next-embassy-id uint u1)
;; Counter for activity IDs
(define-data-var next-activity-id uint u1)

;; Register a new embassy
(define-public (register-embassy
  (embassy-name (string-ascii 100))
  (home-reality (string-ascii 50))
  (host-reality (string-ascii 50))
  (coordinates (list 5 int))
  (staff-count uint))
  (let ((embassy-id (var-get next-embassy-id)))
    (map-set embassies
      { embassy-id: embassy-id }
      {
        embassy-name: embassy-name,
        home-reality: home-reality,
        host-reality: host-reality,
        coordinates: coordinates,
        establishment-date: block-height,
        ambassador: tx-sender,
        staff-count: staff-count,
        status: "active"
      }
    )
    (var-set next-embassy-id (+ embassy-id u1))
    (ok embassy-id)
  )
)

;; Appoint a new ambassador
(define-public (appoint-ambassador (embassy-id uint) (new-ambassador principal))
  (let (
    (embassy (default-to
      {
        embassy-name: "",
        home-reality: "",
        host-reality: "",
        coordinates: (list 0 0 0 0 0),
        establishment-date: u0,
        ambassador: tx-sender,
        staff-count: u0,
        status: ""
      }
      (map-get? embassies { embassy-id: embassy-id })))
    )

    ;; Update embassy
    (map-set embassies
      { embassy-id: embassy-id }
      (merge embassy { ambassador: new-ambassador })
    )

    (ok true)
  )
)

;; Record an embassy activity
(define-public (record-activity
  (embassy-id uint)
  (activity-type (string-ascii 50))
  (activity-description (string-ascii 200))
  (participants (list 5 principal))
  (outcome (string-ascii 100)))
  (let (
    (embassy (default-to
      {
        embassy-name: "",
        home-reality: "",
        host-reality: "",
        coordinates: (list 0 0 0 0 0),
        establishment-date: u0,
        ambassador: tx-sender,
        staff-count: u0,
        status: ""
      }
      (map-get? embassies { embassy-id: embassy-id })))
    (activity-id (var-get next-activity-id))
    )

    ;; Record activity
    (map-set embassy-activities
      { activity-id: activity-id }
      {
        embassy-id: embassy-id,
        activity-type: activity-type,
        activity-description: activity-description,
        participants: participants,
        timestamp: block-height,
        outcome: outcome
      }
    )

    (var-set next-activity-id (+ activity-id u1))
    (ok activity-id)
  )
)

;; Close an embassy
(define-public (close-embassy (embassy-id uint))
  (let (
    (embassy (default-to
      {
        embassy-name: "",
        home-reality: "",
        host-reality: "",
        coordinates: (list 0 0 0 0 0),
        establishment-date: u0,
        ambassador: tx-sender,
        staff-count: u0,
        status: ""
      }
      (map-get? embassies { embassy-id: embassy-id })))
    )

    ;; Update embassy status
    (map-set embassies
      { embassy-id: embassy-id }
      (merge embassy { status: "closed" })
    )

    (ok true)
  )
)

;; Get embassy details
(define-read-only (get-embassy (embassy-id uint))
  (map-get? embassies { embassy-id: embassy-id })
)

;; Get activity details
(define-read-only (get-activity (activity-id uint))
  (map-get? embassy-activities { activity-id: activity-id })
)

;; Get all activities for an embassy (simplified)
(define-read-only (get-embassy-activities (embassy-id uint))
  ;; This is a placeholder - in a real implementation we would need to iterate
  ;; through activities and filter by embassy-id
  (ok "See activities individually by ID")
)

