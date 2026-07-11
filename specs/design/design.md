# Audit Evidence Hub — Design

## 1. Overview

The Audit Evidence Hub is a single-page web application that lets a
compliance team run a SOC2 / ISO 27001 audit end to end: a Compliance Admin
defines controls and assigns them to a team and an auditor, a Team Manager
submits evidence (including image uploads) against the controls owned by
their team, and an Auditor reviews that evidence and approves or rejects it.
All three roles sign in through the organization's existing identity
provider and see a role-specific experience inside the one app. The system
consumes the organization's existing directory (people/teams), asset
registry (products/systems), notification, and object-storage services
rather than re-implementing them, and owns only the audit-specific data:
controls, evidence, and review decisions.

## 2. Components

- **audit-hub-api** (`service`, Go) — the single backend: owns controls,
evidence metadata, review decisions, and the audit trail; enforces
per-role/per-assignment authorization; talks to the org directory, asset
registry, notification, and S3 object-storage dependencies on behalf of
the webapp.
- **audit-hub-webapp** (`web-application`, React) — the single-page app;
one codebase whose navigation and available actions adapt to the
signed-in user's role (Compliance Admin / Team Manager / Auditor).

No separate services are justified: there is one interactive workload
(browse/author controls, upload/review evidence) with one scaling profile
and one technology, so it lands at the standard shape of one backend + one
SPA.

## 3. Capabilities

### audit-hub-api

- **Control management** — create, edit, archive a control (title,
framework reference e.g. "ISO 27001 A.9.2.3", requirement description);
assign it to exactly one team; scope it to one product/system; assign one
or more auditors. (FR-5..FR-9, FR-12)
- **Control visibility** — list/filter controls: all controls with status
for the Compliance Admin; only controls assigned to the caller's team for
a Team Manager; only controls assigned to the caller as reviewer for an
Auditor. (FR-10, FR-13, FR-18, FR-19, FR-24)
- **Evidence submission** — accept evidence (image upload(s) + free-text
note) against a control, keyed to the submitting team; support
re-submission after rejection. (FR-15, FR-15a, FR-17)
- **Evidence storage integration** — persist uploaded evidence images
durably in S3 object storage; store only the object key + metadata in the
database. (FR-15a, NFR-7)
- **Review workflow** — let an assigned auditor approve or reject
submitted evidence with an optional (approve) / required (reject)
comment; approving marks the control satisfied for the cycle, rejecting
returns it to the team for re-submission. (FR-21, FR-22)
- **History &amp; audit trail** — expose full submission/review history per
control, and an immutable audit trail of control edits, submissions, and
review decisions, attributable to an authenticated user. (FR-11, FR-23,
FR-25, NFR-2, NFR-3)
- **Org data lookups** — resolve teams, people (auditors/managers), and
products/systems from the organization's existing directory and asset
registry services at request time (never duplicated locally). (FR-7,
FR-8, FR-9, NFR-4)
- **Notifications** — send an email via the organization's notification
service whenever a user action is needed: a Team Manager when a control
is newly assigned to their team or when their evidence is rejected; an
Auditor when evidence is submitted/re-submitted for a control assigned to
them. (FR-26, FR-26a)
- **Authorization** — enforce per-role, per-assignment access to every
control/evidence/review record on every request. (FR-3, NFR-1)

### audit-hub-webapp

- **Sign-in** — authenticate every user via the organization's identity
provider before showing any audit data. (FR-1, FR-2, FR-4)
- **Role-adaptive shell** — one SPA whose navigation and screens switch
based on the signed-in user's role. (FR-27)
- **Compliance Admin console** — control CRUD, team/scope/auditor
assignment, full-visibility control list, evidence &amp; review history
viewer. (FR-5..FR-12)
- **Team Manager workspace** — "my team's controls" list, control detail,
evidence submission form (image upload + note), status/feedback view,
re-submission flow. (FR-13..FR-18)
- **Auditor review queue** — "assigned to me" list, control/evidence
detail viewer, approve/reject action with comment, submission history.
(FR-19..FR-24)

## 4. Data model

- **Control** — id, title, description, frameworkReference (e.g. "ISO
27001 A.9.2.3"), status (not\_started, evidence\_submitted, approved,
rejected), teamId (org directory reference), productSystemId (asset
registry reference), auditorIds (org directory references), createdBy,
createdAt, updatedAt.
- **EvidenceSubmission** — id, controlId, submittedBy, submittedAt, note
(text), images (list of `EvidenceImage`), status (pending, approved,
rejected).
- **EvidenceImage** — id, evidenceSubmissionId, s3ObjectKey, contentType,
sizeBytes, originalFilename, uploadedAt.
- **ReviewDecision** — id, evidenceSubmissionId, reviewerId, decision
(approved/rejected), comment, decidedAt (immutable once written).
- **AuditTrailEntry** — id, entityType (control/evidence/review), entityId,
actorId, action, details, occurredAt.

Relationships: a Control has one team and one product/system (by
reference), one or more auditors (by reference), and many
EvidenceSubmissions; an EvidenceSubmission has many EvidenceImages and at
most one ReviewDecision per submission cycle.

## 5. Roles &amp; access

- **Compliance Admin** — full CRUD on controls and their team/scope/auditor
assignment; read access to every control, evidence submission, and review
decision.
- **Team Manager** — read access limited to controls assigned to their
team; may create evidence submissions on those controls; cannot see or
act on other teams' controls.
- **Auditor** — read access limited to controls where they are an assigned
reviewer; may record approve/reject decisions on evidence for those
controls; cannot see or act on controls they are not assigned to review.

Role is derived from the organization's identity provider / org directory
at sign-in and enforced by the backend on every request (never
client-side-only).

## 6. Interactions

- `audit-hub-webapp` → `audit-hub-api`: all reads/writes for controls,
evidence, and review decisions (JWT-authenticated).
- `audit-hub-webapp` &amp; `audit-hub-api` → `user-auth` (Thunder/platform
identity): end-user sign-in and JWT issuance/validation.
- `audit-hub-api` → org directory service (`org-service`): resolve teams,
managers, and auditors for assignment and role/team-scoped filtering.
- `audit-hub-api` → asset/product registry service (`org-service`):
resolve the product/system a control is scoped to.
- `audit-hub-api` → notification service (`org-service`): send action-
required emails to Team Managers and Auditors.
- `audit-hub-api` → object storage (`external`, S3): store and retrieve
uploaded evidence images.

## 7. Data flow

1. **Control setup**: Compliance Admin signs in → creates a control →
 selects a team (from directory), a product/system (from registry), and
 one or more auditors (from directory) → `audit-hub-api` persists the
 control and sends the assigned team an action-required email.
2. **Evidence submission**: Team Manager signs in → sees controls assigned
 to their team → opens a control → uploads image(s) to S3 via
 `audit-hub-api` and adds a note → `audit-hub-api` creates an
 EvidenceSubmission, updates control status, records an audit-trail
 entry, and emails the assigned auditor(s).
3. **Review**: Auditor signs in → sees controls assigned to them → opens
 the submission, views the note and images → approves (control marked
 satisfied) or rejects with a required comment (control returned to the
 team, which is emailed) → `audit-hub-api` records the immutable
 ReviewDecision and audit-trail entry.
4. **Re-submission**: on rejection, the Team Manager sees the reviewer's
 comment, submits new/additional evidence, and the cycle repeats from
 step 2 for that control.



# Audit Evidence Hub — Design

## 1. Overview

The Audit Evidence Hub is a single-page web application that lets a
compliance team run a SOC2 / ISO 27001 audit end to end: a Compliance Admin
defines controls and assigns them to a team and an auditor, a Team Manager
submits evidence (including image uploads) against the controls owned by
their team, and an Auditor reviews that evidence and approves or rejects it.
All three roles sign in through the organization's existing identity
provider and see a role-specific experience inside the one app. The system
consumes the organization's existing directory (people/teams), asset
registry (products/systems), notification, and object-storage services
rather than re-implementing them, and owns only the audit-specific data:
controls, evidence, and review decisions.

## 2. Components

- **audit-hub-api** (`service`, Go) — the single backend: owns controls,
evidence metadata, review decisions, and the audit trail; enforces
per-role/per-assignment authorization; talks to the org directory, asset
registry, notification, and S3 object-storage dependencies on behalf of
the webapp.
- **audit-hub-webapp** (`web-application`, React) — the single-page app;
one codebase whose navigation and available actions adapt to the
signed-in user's role (Compliance Admin / Team Manager / Auditor).

No separate services are justified: there is one interactive workload
(browse/author controls, upload/review evidence) with one scaling profile
and one technology, so it lands at the standard shape of one backend + one
SPA.

## 3. Capabilities

### audit-hub-api

- **Control management** — create, edit, archive a control (title,
framework reference e.g. "ISO 27001 A.9.2.3", requirement description);
assign it to exactly one team; scope it to one product/system; assign one
or more auditors. (FR-5..FR-9, FR-12)
- **Control visibility** — list/filter controls: all controls with status
for the Compliance Admin; only controls assigned to the caller's team for
a Team Manager; only controls assigned to the caller as reviewer for an
Auditor. (FR-10, FR-13, FR-18, FR-19, FR-24)
- **Evidence submission** — accept evidence (image upload(s) + free-text
note) against a control, keyed to the submitting team; support
re-submission after rejection. (FR-15, FR-15a, FR-17)
- **Evidence storage integration** — persist uploaded evidence images
durably in S3 object storage; store only the object key + metadata in the
database. (FR-15a, NFR-7)
- **Review workflow** — let an assigned auditor approve or reject
submitted evidence with an optional (approve) / required (reject)
comment; approving marks the control satisfied for the cycle, rejecting
returns it to the team for re-submission. (FR-21, FR-22)
- **History &amp; audit trail** — expose full submission/review history per
control, and an immutable audit trail of control edits, submissions, and
review decisions, attributable to an authenticated user. (FR-11, FR-23,
FR-25, NFR-2, NFR-3)
- **Org data lookups** — resolve teams, people (auditors/managers), and
products/systems from the organization's existing directory and asset
registry services at request time (never duplicated locally). (FR-7,
FR-8, FR-9, NFR-4)
- **Notifications** — send an email via the organization's notification
service whenever a user action is needed: a Team Manager when a control
is newly assigned to their team or when their evidence is rejected; an
Auditor when evidence is submitted/re-submitted for a control assigned to
them. (FR-26, FR-26a)
- **Authorization** — enforce per-role, per-assignment access to every
control/evidence/review record on every request. (FR-3, NFR-1)

### audit-hub-webapp

- **Sign-in** — authenticate every user via the organization's identity
provider before showing any audit data. (FR-1, FR-2, FR-4)
- **Role-adaptive shell** — one SPA whose navigation and screens switch
based on the signed-in user's role. (FR-27)
- **Compliance Admin console** — control CRUD, team/scope/auditor
assignment, full-visibility control list, evidence &amp; review history
viewer. (FR-5..FR-12)
- **Team Manager workspace** — "my team's controls" list, control detail,
evidence submission form (image upload + note), status/feedback view,
re-submission flow. (FR-13..FR-18)
- **Auditor review queue** — "assigned to me" list, control/evidence
detail viewer, approve/reject action with comment, submission history.
(FR-19..FR-24)

## 4. Data model

- **Control** — id, title, description, frameworkReference (e.g. "ISO
27001 A.9.2.3"), status (not\_started, evidence\_submitted, approved,
rejected), teamId (org directory reference), productSystemId (asset
registry reference), auditorIds (org directory references), createdBy,
createdAt, updatedAt.
- **EvidenceSubmission** — id, controlId, submittedBy, submittedAt, note
(text), images (list of `EvidenceImage`), status (pending, approved,
rejected).
- **EvidenceImage** — id, evidenceSubmissionId, s3ObjectKey, contentType,
sizeBytes, originalFilename, uploadedAt.
- **ReviewDecision** — id, evidenceSubmissionId, reviewerId, decision
(approved/rejected), comment, decidedAt (immutable once written).
- **AuditTrailEntry** — id, entityType (control/evidence/review), entityId,
actorId, action, details, occurredAt.

Relationships: a Control has one team and one product/system (by
reference), one or more auditors (by reference), and many
EvidenceSubmissions; an EvidenceSubmission has many EvidenceImages and at
most one ReviewDecision per submission cycle.

## 5. Roles &amp; access

- **Compliance Admin** — full CRUD on controls and their team/scope/auditor
assignment; read access to every control, evidence submission, and review
decision.
- **Team Manager** — read access limited to controls assigned to their
team; may create evidence submissions on those controls; cannot see or
act on other teams' controls.
- **Auditor** — read access limited to controls where they are an assigned
reviewer; may record approve/reject decisions on evidence for those
controls; cannot see or act on controls they are not assigned to review.

Role is derived from the organization's identity provider / org directory
at sign-in and enforced by the backend on every request (never
client-side-only).

## 6. Interactions

- `audit-hub-webapp` → `audit-hub-api`: all reads/writes for controls,
evidence, and review decisions (JWT-authenticated).
- `audit-hub-webapp` &amp; `audit-hub-api` → `user-auth` (Thunder/platform
identity): end-user sign-in and JWT issuance/validation.
- `audit-hub-api` → org directory service (`org-service`): resolve teams,
managers, and auditors for assignment and role/team-scoped filtering.
- `audit-hub-api` → asset/product registry service (`org-service`):
resolve the product/system a control is scoped to.
- `audit-hub-api` → notification service (`org-service`): send action-
required emails to Team Managers and Auditors.
- `audit-hub-api` → object storage (`external`, S3): store and retrieve
uploaded evidence images.

## 7. Data flow

1. **Control setup**: Compliance Admin signs in → creates a control →
selects a team (from directory), a product/system (from registry), and
one or more auditors (from directory) → `audit-hub-api` persists the
control and sends the assigned team an action-required email.
2. **Evidence submission**: Team Manager signs in → sees controls assigned
to their team → opens a control → uploads image(s) to S3 via
`audit-hub-api` and adds a note → `audit-hub-api` creates an
EvidenceSubmission, updates control status, records an audit-trail
entry, and emails the assigned auditor(s).
3. **Review**: Auditor signs in → sees controls assigned to them → opens
the submission, views the note and images → approves (control marked
satisfied) or rejects with a required comment (control returned to the
team, which is emailed) → `audit-hub-api` records the immutable
ReviewDecision and audit-trail entry.
4. **Re-submission**: on rejection, the Team Manager sees the reviewer's
comment, submits new/additional evidence, and the cycle repeats from
step 2 for that control.