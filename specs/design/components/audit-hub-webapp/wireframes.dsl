// Audit Evidence Hub — role-adaptive SPA, desktop 1280x800

screen AdminControlList
  navbar "Audit Hub | Controls | Reports | Profile"
  sidebar "All Controls | Teams | Products | Audit Trail"
  heading "All Controls" 280,80
  input "search controls" 280,130 320x36
  input "status (dropdown)" 620,130 240x36
  table "Control | Team | Product/System | Auditor(s) | Status" 280,190 940x360
  button "New control" 1080,80 140x40

flow
  AdminControlList -> AdminControlForm
  AdminControlList -> AdminControlDetail
  AdminControlDetail -> AdminControlForm

screen AdminControlForm
  navbar "Audit Hub | Controls | Reports | Profile"
  sidebar "All Controls | Teams | Products | Audit Trail"
  heading "New Control" 280,80
  input "title" 280,130 640x36
  input "framework reference (e.g. ISO 27001 A.9.2.3)" 280,182 640x36
  input "requirement description" 280,234 640x72
  input "team (dropdown)" 280,322 300x36
  input "product/system (dropdown)" 620,322 300x36
  input "auditors (multi-select)" 280,374 640x36
  button "Cancel" 280,440 140x40
  button "Save control" 440,440 160x40

screen AdminControlDetail
  navbar "Audit Hub | Controls | Reports | Profile"
  sidebar "All Controls | Teams | Products | Audit Trail"
  heading "Control: A.9.2.3 — Access provisioning" 280,80
  text "Team: Platform | Product/System: Billing Service | Status: evidence_submitted" 280,120
  heading "Evidence submissions" 280,160
  table "Submitted | By | Note | Status" 280,200 940x220
  heading "Audit trail" 280,440
  table "When | Actor | Action" 280,480 940x200
  button "Edit assignment" 280,700 180x40

screen ManagerControlList
  navbar "Audit Hub | My Team's Controls | Profile"
  sidebar "Assigned to My Team | Submitted | Needs Re-submission"
  heading "Controls Assigned to My Team" 280,80
  table "Control | Framework Ref | Product/System | Status" 280,140 940x360
  text "Selecting a control opens its detail and evidence form" 280,520

flow
  ManagerControlList -> ManagerControlDetail

screen ManagerControlDetail
  navbar "Audit Hub | My Team's Controls | Profile"
  sidebar "Assigned to My Team | Submitted | Needs Re-submission"
  heading "Control: A.9.2.3 — Access provisioning" 280,80
  text "Requirement: Access is provisioned via documented approval workflow" 280,120
  text "Status: rejected — Reviewer comment: missing approval log for Q2" 280,150
  heading "Submit Evidence" 280,200
  input "upload image(s)" 280,240 640x72
  input "note describing how evidence satisfies the control" 280,330 640x100
  button "Submit evidence" 280,450 180x40

flow
  ManagerControlDetail -> ManagerControlList

screen AuditorQueue
  navbar "Audit Hub | Review Queue | Profile"
  sidebar "Assigned to Me | Pending Review | Reviewed"
  heading "Controls Assigned to Me for Review" 280,80
  table "Control | Team | Framework Ref | Status" 280,140 940x360
  text "Selecting a control opens the evidence for review" 280,520

flow
  AuditorQueue -> AuditorReview

screen AuditorReview
  navbar "Audit Hub | Review Queue | Profile"
  sidebar "Assigned to Me | Pending Review | Reviewed"
  heading "Review: A.9.2.3 — Access provisioning" 280,80
  text "Submitted by: Platform team — 2024-05-01" 280,120
  image "evidence-screenshot-1.png" 280,150 240x140
  image "evidence-screenshot-2.png" 540,150 240x140
  text "Note: approval workflow screenshots attached from IAM console" 280,310
  heading "Prior submissions" 280,360
  table "Submitted | Decision | Reviewer | Comment" 280,400 940x180
  input "decision comment (required if rejecting)" 280,600 640x72
  button "Reject" 280,690 140x40
  button "Approve" 440,690 140x40

flow
  AuditorReview -> AuditorQueue
