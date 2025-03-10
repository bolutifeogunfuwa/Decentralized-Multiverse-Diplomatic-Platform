;; Cross-Universal Conflict Resolution Contract
;; Resolves conflicts between different universes in the multiverse

(define-data-var admin principal tx-sender)

;; Data structure for conflicts
(define-map conflicts
  { conflict-id: uint }
  {
    conflict-name: (string-ascii 100),
    involved-realities: (list 5 (string-ascii 50)),
    conflict-description: (string-ascii 200),
    severity-level: uint,
    registration-timestamp: uint,
    resolution-deadline: uint,
    status: (string-ascii 20)
  }
)

;; Resolution proposals
(define-map resolution-proposals
  { proposal-id: uint }
  {
    conflict-id: uint,
    proposer: principal,
    proposer-reality: (string-ascii 50),
    resolution-terms: (string-ascii 200),
    proposal-timestamp: uint,
    votes-for: uint,
    votes-against: uint,
    status: (string-ascii 20)
  }
)

;; Votes on proposals
(define-map proposal-votes
  { proposal-id: uint, voter: principal }
  {
    voter-reality: (string-ascii 50),
    vote-type: bool,
    vote-timestamp: uint,
    vote-reason: (string-ascii 100)
  }
)

;; Counter for conflict IDs
(define-data-var next-conflict-id uint u1)
;; Counter for proposal IDs
(define-data-var next-proposal-id uint u1)

;; Register a new conflict
(define-public (register-conflict
  (conflict-name (string-ascii 100))
  (involved-realities (list 5 (string-ascii 50)))
  (conflict-description (string-ascii 200))
  (severity-level uint)
  (resolution-timeframe uint))
  (let (
    (conflict-id (var-get next-conflict-id))
    (deadline (+ block-height resolution-timeframe))
    )
    (map-set conflicts
      { conflict-id: conflict-id }
      {
        conflict-name: conflict-name,
        involved-realities: involved-realities,
        conflict-description: conflict-description,
        severity-level: severity-level,
        registration-timestamp: block-height,
        resolution-deadline: deadline,
        status: "active"
      }
    )
    (var-set next-conflict-id (+ conflict-id u1))
    (ok conflict-id)
  )
)

;; Propose a resolution
(define-public (propose-resolution
  (conflict-id uint)
  (proposer-reality (string-ascii 50))
  (resolution-terms (string-ascii 200)))
  (let (
    (conflict (default-to
      {
        conflict-name: "",
        involved-realities: (list),
        conflict-description: "",
        severity-level: u0,
        registration-timestamp: u0,
        resolution-deadline: u0,
        status: ""
      }
      (map-get? conflicts { conflict-id: conflict-id })))
    (proposal-id (var-get next-proposal-id))
    )

    (map-set resolution-proposals
      { proposal-id: proposal-id }
      {
        conflict-id: conflict-id,
        proposer: tx-sender,
        proposer-reality: proposer-reality,
        resolution-terms: resolution-terms,
        proposal-timestamp: block-height,
        votes-for: u0,
        votes-against: u0,
        status: "proposed"
      }
    )

    (var-set next-proposal-id (+ proposal-id u1))
    (ok proposal-id)
  )
)

;; Vote on a resolution proposal
(define-public (vote-on-proposal
  (proposal-id uint)
  (voter-reality (string-ascii 50))
  (vote-type bool)
  (vote-reason (string-ascii 100)))
  (let (
    (proposal (default-to
      {
        conflict-id: u0,
        proposer: tx-sender,
        proposer-reality: "",
        resolution-terms: "",
        proposal-timestamp: u0,
        votes-for: u0,
        votes-against: u0,
        status: ""
      }
      (map-get? resolution-proposals { proposal-id: proposal-id })))
    (votes-for (get votes-for proposal))
    (votes-against (get votes-against proposal))
    )

    ;; Record vote
    (map-set proposal-votes
      { proposal-id: proposal-id, voter: tx-sender }
      {
        voter-reality: voter-reality,
        vote-type: vote-type,
        vote-timestamp: block-height,
        vote-reason: vote-reason
      }
    )

    ;; Update vote counts
    (map-set resolution-proposals
      { proposal-id: proposal-id }
      (merge proposal {
        votes-for: (if vote-type (+ votes-for u1) votes-for),
        votes-against: (if vote-type votes-against (+ votes-against u1))
      })
    )

    (ok true)
  )
)

;; Finalize a resolution
(define-public (finalize-resolution (proposal-id uint))
  (let (
    (proposal (default-to
      {
        conflict-id: u0,
        proposer: tx-sender,
        proposer-reality: "",
        resolution-terms: "",
        proposal-timestamp: u0,
        votes-for: u0,
        votes-against: u0,
        status: ""
      }
      (map-get? resolution-proposals { proposal-id: proposal-id })))
    (conflict-id (get conflict-id proposal))
    (votes-for (get votes-for proposal))
    (votes-against (get votes-against proposal))
    (new-status (if (> votes-for votes-against) "accepted" "rejected"))
    )

    ;; Update proposal status
    (map-set resolution-proposals
      { proposal-id: proposal-id }
      (merge proposal { status: new-status })
    )

    ;; If accepted, update conflict status
    (if (is-eq new-status "accepted")
      (let (
        (conflict (default-to
          {
            conflict-name: "",
            involved-realities: (list),
            conflict-description: "",
            severity-level: u0,
            registration-timestamp: u0,
            resolution-deadline: u0,
            status: ""
          }
          (map-get? conflicts { conflict-id: conflict-id })))
        )
        (map-set conflicts
          { conflict-id: conflict-id }
          (merge conflict { status: "resolved" })
        )
      )
      true
    )

    (ok new-status)
  )
)

;; Get conflict details
(define-read-only (get-conflict (conflict-id uint))
  (map-get? conflicts { conflict-id: conflict-id })
)

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
  (map-get? resolution-proposals { proposal-id: proposal-id })
)

;; Get vote details
(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? proposal-votes { proposal-id: proposal-id, voter: voter })
)

