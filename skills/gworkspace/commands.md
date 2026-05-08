# gws Command Reference

> For any operation not listed here, run `gws <service> --help` or `gws <service> <resource> <method> --help` to discover the correct syntax.

## Contents
- [Drive](#drive)
- [Gmail](#gmail)
- [Calendar](#calendar)
- [Docs](#docs)
- [Sheets](#sheets)
- [Chat](#chat)
- [Utilities](#utilities)

---

## Drive

```bash
# List files (paginated)
gws drive files list --params '{"pageSize": 20}'
gws drive files list --params '{"pageSize": 100}' --page-all | jq -r '.files[] | {name, id}'

# Search files
gws drive files list --params '{"q": "name contains \"report\""}'
gws drive files list --params '{"q": "mimeType = \"application/vnd.google-apps.document\""}'
gws drive files list --params '{"q": "\"FOLDER_ID\" in parents"}'

# Download file
gws drive files get --params '{"fileId": "FILE_ID", "alt": "media"}' > output.pdf

# Upload file
gws drive +upload ./report.pdf --name "Q1 Report"
gws drive files create --json '{"name": "report.pdf", "parents": ["FOLDER_ID"]}' --upload ./report.pdf

# Create folder
gws drive files create --json '{"name": "My Folder", "mimeType": "application/vnd.google-apps.folder"}'

# Get file metadata
gws drive files get --params '{"fileId": "FILE_ID"}'

# Update file metadata
gws drive files update --params '{"fileId": "FILE_ID"}' --json '{"name": "New Name"}'

# Share file
gws drive permissions create \
  --params '{"fileId": "FILE_ID"}' \
  --json '{"role": "reader", "type": "user", "emailAddress": "user@example.com"}'

# Move file to folder
gws drive files update \
  --params '{"fileId": "FILE_ID", "addParents": "FOLDER_ID", "removeParents": "OLD_PARENT_ID"}' \
  --json '{}'

# Delete file
gws drive files delete --params '{"fileId": "FILE_ID"}'
```

---

## Gmail

```bash
# List messages (latest 10)
gws gmail users messages list --params '{"userId": "me", "maxResults": 10}'

# Search messages
gws gmail users messages list --params '{"userId": "me", "q": "from:sender@example.com is:unread"}'
gws gmail users messages list --params '{"userId": "me", "q": "subject:invoice after:2024/01/01"}'

# Read message (full)
gws gmail users messages get --params '{"userId": "me", "id": "MESSAGE_ID"}'

# Read message (metadata only)
gws gmail users messages get --params '{"userId": "me", "id": "MESSAGE_ID", "format": "metadata"}'

# Send email
gws gmail +send --to alice@example.com --subject "Hello" --body "Hi there"

# Reply to message
gws gmail +reply --message-id MESSAGE_ID --body "Thanks!"

# Reply all
gws gmail +reply-all --message-id MESSAGE_ID --body "Response for everyone"

# Forward message
gws gmail +forward --message-id MESSAGE_ID --to recipient@example.com

# Show unread triage summary
gws gmail +triage

# Label a message
gws gmail users messages modify \
  --params '{"userId": "me", "id": "MESSAGE_ID"}' \
  --json '{"addLabelIds": ["LABEL_ID"]}'

# Mark as read
gws gmail users messages modify \
  --params '{"userId": "me", "id": "MESSAGE_ID"}' \
  --json '{"removeLabelIds": ["UNREAD"]}'

# List labels
gws gmail users labels list --params '{"userId": "me"}'

# Trash message
gws gmail users messages trash --params '{"userId": "me", "id": "MESSAGE_ID"}'
```

---

## Calendar

```bash
# Show agenda (today + upcoming)
gws calendar +agenda
gws calendar +agenda --today --timezone America/New_York

# List events
gws calendar events list --params '{"calendarId": "primary"}'
gws calendar events list --params '{"calendarId": "primary", "maxResults": 20, "orderBy": "startTime", "singleEvents": true, "timeMin": "2024-01-01T00:00:00Z"}'

# Get single event
gws calendar events get --params '{"calendarId": "primary", "eventId": "EVENT_ID"}'

# Create event (helper)
gws calendar +insert --summary "Team Standup" --start "2024-06-10T09:00:00"

# Create event (full control)
gws calendar events insert \
  --params '{"calendarId": "primary"}' \
  --json '{
    "summary": "Meeting",
    "start": {"dateTime": "2024-06-10T10:00:00", "timeZone": "America/New_York"},
    "end": {"dateTime": "2024-06-10T11:00:00", "timeZone": "America/New_York"},
    "attendees": [{"email": "colleague@example.com"}]
  }'

# Update event
gws calendar events patch \
  --params '{"calendarId": "primary", "eventId": "EVENT_ID"}' \
  --json '{"summary": "Updated Title"}'

# Delete event
gws calendar events delete --params '{"calendarId": "primary", "eventId": "EVENT_ID"}'

# List calendars
gws calendar calendarList list
```

---

## Docs

```bash
# Read document content
gws docs documents get --params '{"documentId": "DOC_ID"}'

# Get document text only (extract from JSON)
gws docs documents get --params '{"documentId": "DOC_ID"}' | jq '[.body.content[].paragraph.elements[]?.textRun?.content] | join("")'

# List tabs in a multi-tab document
gws docs documents get --params '{"documentId": "DOC_ID", "includeTabsContent": true}' \
  | jq '[.tabs[]? | {tabId: .tabProperties.tabId, title: .tabProperties.title}]'

# Read content from a specific tab by title (note: .documentTab.body, not .body)
gws docs documents get --params '{"documentId": "DOC_ID", "includeTabsContent": true}' \
  | jq '.tabs[] | select(.tabProperties.title == "TAB_TITLE") | .documentTab.body.content[]?.paragraph?.elements[]?.textRun?.content'

# Create document
gws docs documents create --json '{"title": "My New Document"}'

# Append text to document
gws docs +write --document-id DOC_ID --text "New paragraph text here"

# Batch update (insert text at index)
gws docs documents batchUpdate \
  --params '{"documentId": "DOC_ID"}' \
  --json '{
    "requests": [{
      "insertText": {
        "location": {"index": 1},
        "text": "Inserted text\n"
      }
    }]
  }'

# Replace text in document
gws docs documents batchUpdate \
  --params '{"documentId": "DOC_ID"}' \
  --json '{
    "requests": [{
      "replaceAllText": {
        "containsText": {"text": "old text"},
        "replaceText": "new text"
      }
    }]
  }'
```

---

## Sheets

```bash
# Read a range
gws sheets spreadsheets values get \
  --params '{"spreadsheetId": "SPREADSHEET_ID", "range": "Sheet1!A1:D20"}'

# Read helper
gws sheets +read --spreadsheet SPREADSHEET_ID --range "Sheet1!A1:C10"

# Read all sheet names
gws sheets spreadsheets get \
  --params '{"spreadsheetId": "SPREADSHEET_ID"}' | jq '.sheets[].properties.title'

# Append rows
gws sheets spreadsheets values append \
  --params '{"spreadsheetId": "SPREADSHEET_ID", "range": "Sheet1!A1", "valueInputOption": "USER_ENTERED"}' \
  --json '{"values": [["Alice", "95", "2024-06-10"], ["Bob", "87", "2024-06-10"]]}'

# Append helper
gws sheets +append --spreadsheet SPREADSHEET_ID --values "Alice,95,2024-06-10"

# Update a range
gws sheets spreadsheets values update \
  --params '{"spreadsheetId": "SPREADSHEET_ID", "range": "Sheet1!B2", "valueInputOption": "USER_ENTERED"}' \
  --json '{"values": [["Updated value"]]}'

# Clear a range
gws sheets spreadsheets values clear \
  --params '{"spreadsheetId": "SPREADSHEET_ID", "range": "Sheet1!A1:D10"}' \
  --json '{}'

# Create spreadsheet
gws sheets spreadsheets create --json '{"properties": {"title": "Q1 Budget"}}'

# Add a new sheet tab
gws sheets spreadsheets batchUpdate \
  --params '{"spreadsheetId": "SPREADSHEET_ID"}' \
  --json '{"requests": [{"addSheet": {"properties": {"title": "New Tab"}}}]}'
```

---

## Chat

```bash
# Send message to a space
gws chat +send --space spaces/SPACE_ID --text "Deploy complete."

# Send message (full API)
gws chat spaces messages create \
  --params '{"parent": "spaces/SPACE_ID"}' \
  --json '{"text": "Hello from gws!"}'

# List spaces
gws chat spaces list

# List messages in a space
gws chat spaces messages list --params '{"parent": "spaces/SPACE_ID"}'
```

---

## Utilities

```bash
# Inspect API schema for any resource
gws schema drive.files.list
gws schema gmail.users.messages.get

# Dry-run (preview without executing)
gws drive files list --params '{"pageSize": 5}' --dry-run

# Paginate all results
gws drive files list --params '{"pageSize": 100}' --page-all
gws drive files list --params '{"pageSize": 100}' --page-all --page-limit 5

# Auth management
gws auth setup                              # First-time OAuth setup
gws auth export                             # View current credentials
gws auth export --unmasked > creds.json     # Export for CI/headless use
```
