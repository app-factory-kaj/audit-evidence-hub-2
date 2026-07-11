# Requirements Specification — Audit Evidence Hub

## 1. Purpose

The Audit Evidence Hub is a single-page web application that supports the
compliance team in running SOC2 / ISO 27001 audits. It centralizes the
lifecycle of a control — definition, assignment, evidence submission, and
auditor review — for three distinct roles who all sign in through the
organization's existing identity provider and are presented with a
role-specific experience within the same application.

## 2. Roles

A user's role is determined by the organization's identity provider / org
directory and is not self-assignable within the app. A user has exactly one
of the three roles for the purposes of this system.

## 3. Functional Requirements

### 3.1 Authentication &amp; Authorization

- FR-1: The system SHALL require every user to authenticate via the
organization's existing identity provider before accessing any part of the
application.
- FR-2: The system SHALL determine the signed-in user's role (Compliance
Admin, Team Manager, or Auditor) and SHALL render a role-appropriate
experience after sign-in.
- FR-3: The system SHALL restrict every action and every piece of data shown
to what is permitted for the signed-in user's role, as defined in sections
3.2–3.4.
- FR-4: If a user has no recognized role, the system SHALL deny access to
audit data and SHALL display an explanatory message.

### 3.2 Compliance Admin capabilities

- FR-5: The Compliance Admin SHALL be able to create a control, specifying
at minimum: a title, a description of the requirement (e.g. the text of an
ISO 27001 clause or SOC2 criterion), and a reference/citation identifier
(e.g. "ISO 27001 A.9.2.3").
- FR-6: The Compliance Admin SHALL be able to edit and delete (or archive) a
control they created.
- FR-7: The Compliance Admin SHALL be able to assign a control to exactly
one responsible team, drawn from the organization's existing team
directory.
- FR-8: The Compliance Admin SHALL be able to scope a control to one product
or system under audit, drawn from the organization's existing
products/systems registry.
- FR-9: The Compliance Admin SHALL be able to assign a control to one or
more auditors, drawn from the organization's existing people directory,
who are responsible for reviewing evidence submitted against it.
- FR-10: The Compliance Admin SHALL be able to view every control in the
system regardless of assigned team, scope, or auditor, along with its
current status (e.g. not started, evidence submitted, approved, rejected).
- FR-11: The Compliance Admin SHALL be able to view all evidence submitted
for any control and the full review history (who reviewed it, decision,
timestamp, and any reviewer comments).
- FR-12: The Compliance Admin SHALL be able to change a control's team
assignment, scope, or auditor assignment after creation.

### 3.3 Team Manager capabilities

- FR-13: The Team Manager SHALL see only the controls assigned to the
team(s) they manage.
- FR-14: The Team Manager SHALL be able to view the full detail of a control
assigned to their team, including its description, reference identifier,
scoped product/system, and current status.
- FR-15: The Team Manager SHALL be able to submit evidence against a control
assigned to their team. Evidence SHALL support at least: image uploads (e.g.
screenshots, photos of physical controls, exported log/report captures) and a
free text note describing how the evidence satisfies the control.
- FR-15a: Every image uploaded as evidence SHALL be durably persisted by the
system and SHALL remain retrievable (for viewing/download by the Compliance
Admin, the submitting Team Manager's team, and the assigned Auditor) for as
long as the associated control record exists.
- FR-16: The Team Manager SHALL be able to view the status and any reviewer
feedback for controls their team has submitted evidence for.
- FR-17: The Team Manager SHALL be able to re-submit or add additional
evidence to a control that was rejected by an auditor.
- FR-18: The Team Manager SHALL NOT be able to view or act on controls not
assigned to their team.

### 3.4 Auditor capabilities

- FR-19: The Auditor SHALL see only the controls for which they are the
assigned reviewer.
- FR-20: The Auditor SHALL be able to view the control's description,
reference identifier, scoped product/system, and all evidence submitted
against it.
- FR-21: The Auditor SHALL be able to approve or reject submitted evidence,
and SHALL be able to attach a comment explaining the decision (required
when rejecting).
- FR-22: Approving evidence SHALL mark the control as satisfied for the
current audit cycle; rejecting evidence SHALL return the control to the
responsible Team Manager for re-submission.
- FR-23: The Auditor SHALL be able to view the history of prior submissions
and decisions for a control they are reviewing.
- FR-24: The Auditor SHALL NOT be able to view or act on controls for which
they are not the assigned reviewer.

### 3.5 Cross-cutting

- FR-25: The system SHALL maintain an audit trail (who did what, and when)
for control creation/edits, evidence submissions, and review decisions.
- FR-26: The system SHALL notify the relevant users of state-changing events
relevant to them: a Team Manager when their submission is approved or
rejected, and an Auditor when new evidence is submitted for a control they
must review.
- FR-26a: Whenever a user action is required from someone to move a control
forward, the system SHALL send that person an email notification prompting
the action, including at minimum: a Team Manager when a control is newly
assigned to their team (action needed: submit evidence) or when evidence
they submitted is rejected (action needed: re-submit), and an Auditor when
evidence is submitted or re-submitted for a control assigned to them
(action needed: review). The email SHALL identify the control and link to
the relevant view in the application.
- FR-27: The system SHALL present one single-page web application whose
navigation, views, and available actions adapt to the signed-in user's
role, rather than separate applications per role.

## 4. Non-Functional Requirements

- NFR-1 (Security): All access to controls and evidence SHALL be authorized
per-role and per-assignment on every request; role/scope checks SHALL NOT
rely solely on client-side enforcement.
- NFR-2 (Data integrity): Once evidence has been reviewed (approved or
rejected), the review decision and reviewer identity SHALL be immutable;
new submissions SHALL create new evidence records rather than overwrite
prior ones.
- NFR-3 (Auditability): All audit-trail records (FR-25) SHALL be retained
for the life of the audit engagement and SHALL be attributable to a
specific authenticated user.
- NFR-4 (Availability of source data): Team, people, and product/system data
used for assignment and scoping SHALL be sourced from the organization's
existing directories/registries rather than duplicated or manually
re-entered.
- NFR-5 (Usability): Each role's default view SHALL surface only the
controls relevant to that role (per sections 3.2–3.4) without requiring
manual filtering.
- NFR-6 (Traceability): Every control SHALL be traceable to its originating
compliance framework reference (e.g. specific ISO 27001 clause or SOC2
criterion).
- NFR-7 (Evidence storage durability): Uploaded evidence images SHALL be
stored in persistent, durable storage (not local/ephemeral compute storage)
so that they survive application restarts/redeploys and remain accessible
for the life of the audit engagement.

## 5. Out of Scope

- Automated/continuous compliance monitoring or evidence collection from
external systems.
- Managing the organization's identity provider, team directory, people
directory, or product/system registry themselves — this system consumes
them, it does not own or edit them.
- Generating final audit reports/certifications for submission to external
certification bodies (may be a future extension).

## 6. Glossary

- **Control**: A discrete compliance requirement (derived from a framework
such as ISO 27001 or SOC2) that must be satisfied with evidence.
- **Evidence**: Documentation (files and/or notes) submitted to demonstrate
that a control is satisfied.
- **Scope**: The product or system under audit to which a control applies.
- **Review decision**: The Auditor's approval or rejection of submitted
evidence, with optional/required comment.

