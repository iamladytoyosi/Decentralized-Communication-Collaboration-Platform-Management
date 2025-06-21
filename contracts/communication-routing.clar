;; Communication Routing Contract
;; Routes and manages team communications

(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_MESSAGE_NOT_FOUND (err u401))
(define-constant ERR_INVALID_CHANNEL (err u402))
(define-constant ERR_CHANNEL_NOT_FOUND (err u403))

;; Data structures
(define-map channels
  uint
  {
    name: (string-ascii 50),
    team-id: uint,
    created-by: principal,
    created-at: uint,
    active: bool
  }
)

(define-map messages
  uint
  {
    channel-id: uint,
    sender: principal,
    content-hash: (string-ascii 64),
    timestamp: uint,
    message-type: (string-ascii 20)
  }
)

(define-map message-reactions
  {message-id: uint, user: principal}
  {
    reaction: (string-ascii 10),
    timestamp: uint
  }
)

(define-map user-notifications
  {user: principal, notification-id: uint}
  {
    message-id: uint,
    read: bool,
    timestamp: uint
  }
)

;; Data variables
(define-data-var next-channel-id uint u1)
(define-data-var next-message-id uint u1)
(define-data-var next-notification-id uint u1)

;; Public functions
(define-public (create-channel (name (string-ascii 50)) (team-id uint))
  (let ((channel-id (var-get next-channel-id)))
    (map-set channels channel-id {
      name: name,
      team-id: team-id,
      created-by: tx-sender,
      created-at: block-height,
      active: true
    })
    (var-set next-channel-id (+ channel-id u1))
    (ok channel-id)
  )
)

(define-public (send-message (channel-id uint) (content-hash (string-ascii 64)) (message-type (string-ascii 20)))
  (let (
    (channel (unwrap! (map-get? channels channel-id) ERR_CHANNEL_NOT_FOUND))
    (message-id (var-get next-message-id))
  )
    (map-set messages message-id {
      channel-id: channel-id,
      sender: tx-sender,
      content-hash: content-hash,
      timestamp: block-height,
      message-type: message-type
    })
    (var-set next-message-id (+ message-id u1))
    (ok message-id)
  )
)

(define-public (add-reaction (message-id uint) (reaction (string-ascii 10)))
  (let ((message (unwrap! (map-get? messages message-id) ERR_MESSAGE_NOT_FOUND)))
    (map-set message-reactions {message-id: message-id, user: tx-sender} {
      reaction: reaction,
      timestamp: block-height
    })
    (ok true)
  )
)

(define-public (mark-notification-read (notification-id uint))
  (let ((notification (unwrap! (map-get? user-notifications {user: tx-sender, notification-id: notification-id}) ERR_MESSAGE_NOT_FOUND)))
    (map-set user-notifications {user: tx-sender, notification-id: notification-id}
      (merge notification {read: true})
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-channel (channel-id uint))
  (map-get? channels channel-id)
)

(define-read-only (get-message (message-id uint))
  (map-get? messages message-id)
)

(define-read-only (get-message-reaction (message-id uint) (user principal))
  (map-get? message-reactions {message-id: message-id, user: user})
)

(define-read-only (get-user-notification (user principal) (notification-id uint))
  (map-get? user-notifications {user: user, notification-id: notification-id})
)
