#!/usr/bin/env bash
# Web verification setup for the salesperson assignment feature (dev container only).
#  1. Creates/updates a NON-SUPER BC user (default SALESUSER1 / Sales123!) with
#     D365 BASIC + D365 BUS FULL ACCESS + BCGrokBot. No BGB SALESP ADMIN, no BGB SALES BYPASS.
#  2. Runs the idempotent demo data codeunit (test app, OData web service BGBWebDemo):
#     salespersons BGB-SP1 (linked to SALESUSER1) and BGB-SP2, customers BGB-C-OWN (BGB-SP1),
#     BGB-C-OTHER (BGB-SP2), BGB-C-NOSP (no salesperson), and one open order for BGB-C-NOSP.
# Requires: container up (scripts/bc-up.sh), main + test app published (scripts/test-integration.sh).
# Usage: scripts/setup-web-demo.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
need curl; need python3
SALES_USER="${SALES_USER:-SALESUSER1}"
SALES_PASSWORD="${SALES_PASSWORD:-Sales123!}"
SALES_USER_GUID="${SALES_USER_GUID:-b6b00000-0000-0000-0000-00000000a001}"
ODATA="${ODATA_URL:-http://localhost:7048/BC/ODataV4}"
API="${API_URL:-http://localhost:7052/BC/api}"
BC_CONTAINER="${BC_CONTAINER:-msdyn365bconlinux-bc-1}"
BASE_APP_ID="437dbf0e-84ff-417a-965d-ed2bb9650972"
OUR_APP_ID="$(python3 -c 'import json;print(json.load(open("'"$REPO_ROOT"'/app/app.json"))["id"])')"

log "Creating BC user $SALES_USER (non-SUPER)"
HASH=$(printf '%s' "$SALES_PASSWORD" | $SUDO docker exec -i "$BC_CONTAINER" env DOTNET_STARTUP_HOOKS= \
  /bc/tools/NavUserPasswordInspector/NavUserPasswordInspector generate --user-security-id "$SALES_USER_GUID")
[[ "$HASH" =~ ^[A-Za-z0-9+/]{22}==-V3$ ]] || die "password hash generation failed: $HASH"

acl() { # role app-id
  cat <<SQL
IF NOT EXISTS (SELECT 1 FROM [Access Control] WHERE [User Security ID]='$SALES_USER_GUID' AND [Role ID]=N'$1' AND [Company Name]=N'' AND [App ID]='$2')
  INSERT INTO [Access Control] ([User Security ID],[Role ID],[Company Name],[Scope],[App ID],[\$systemId],[\$systemCreatedAt],[\$systemCreatedBy],[\$systemModifiedAt],[\$systemModifiedBy])
  VALUES ('$SALES_USER_GUID',N'$1',N'',0,'$2',NEWID(),GETUTCDATE(),'$SALES_USER_GUID',GETUTCDATE(),'$SALES_USER_GUID');
SQL
}
SQL=$(cat <<SQL
SET NOCOUNT ON;
IF NOT EXISTS (SELECT 1 FROM [User] WHERE [User Security ID]='$SALES_USER_GUID')
  INSERT INTO [User] ([User Security ID],[User Name],[Full Name],[State],[Expiry Date],[Windows Security ID],[Change Password],[License Type],[Authentication Email],[Contact Email],[Exchange Identifier],[Application ID],[\$systemId],[\$systemCreatedAt],[\$systemCreatedBy],[\$systemModifiedAt],[\$systemModifiedBy])
  VALUES ('$SALES_USER_GUID',N'$SALES_USER',N'Sally Sales',0,'1753-01-01',N'S-1-5-21-2074085148-119339936-2019613796-1101',0,0,N'',N'',N'','00000000-0000-0000-0000-000000000000',NEWID(),GETUTCDATE(),'$SALES_USER_GUID',GETUTCDATE(),'$SALES_USER_GUID');
IF NOT EXISTS (SELECT 1 FROM [User Property] WHERE [User Security ID]='$SALES_USER_GUID')
  INSERT INTO [User Property] ([User Security ID],[Password],[Name Identifier],[Authentication Key],[WebServices Key],[WebServices Key Expiry Date],[Authentication Object ID],[Directory Role ID],[Telemetry User ID],[\$systemId],[\$systemCreatedAt],[\$systemCreatedBy],[\$systemModifiedAt],[\$systemModifiedBy])
  VALUES ('$SALES_USER_GUID',N'$HASH',N'',N'',N'','1753-01-01',N'',N'','$SALES_USER_GUID',NEWID(),GETUTCDATE(),'$SALES_USER_GUID',GETUTCDATE(),'$SALES_USER_GUID');
ELSE
  UPDATE [User Property] SET [Password]=N'$HASH' WHERE [User Security ID]='$SALES_USER_GUID';
-- never admin / bypass / SUPER
DELETE FROM [Access Control] WHERE [User Security ID]='$SALES_USER_GUID' AND [Role ID] IN (N'SUPER',N'BGB SALESP ADMIN',N'BGB SALES BYPASS');
$(acl 'D365 BASIC' "$BASE_APP_ID")
$(acl 'D365 BUS FULL ACCESS' "$BASE_APP_ID")
$(acl 'BCGrokBot' "$OUR_APP_ID")
SELECT [Role ID] FROM [Access Control] WHERE [User Security ID]='$SALES_USER_GUID';
SQL
)
$SUDO docker exec -i "$BC_CONTAINER" bash -c '/opt/mssql-tools18/bin/sqlcmd -S "$SQL_SERVER" -U "${BC_DB_USER:-bctest}" -P "${BC_DB_PASSWORD:-Test1234}" -d "$BC_DATABASE" -C -No -b -h -1 -W' <<<"$SQL" \
  || die "user SQL failed"
ok "user $SALES_USER ready"

log "Checking $SALES_USER can sign in (OData, basic auth)"
# a freshly inserted user can take a few seconds to be picked up by the service tier
for _ in $(seq 1 30); do
  code=$(curl -s -o /dev/null -w '%{http_code}' -u "$SALES_USER:$SALES_PASSWORD" "$API/v2.0/companies")
  [ "$code" = "200" ] && break; sleep 2
done
[ "$code" = "200" ] || die "$SALES_USER cannot authenticate (HTTP $code)"
ok "$SALES_USER authenticates (HTTP 200)"

COMPANY=$(curl -sf -u "$BC_AUTH" "$API/v2.0/companies" | python3 -c 'import sys,json,urllib.parse;print(urllib.parse.quote(json.load(sys.stdin)["value"][0]["name"]))')
log "Running demo data setup (OData BGBWebDemo_SetupDemo, as ${BC_AUTH%%:*})"
out=$(curl -s -w '\n%{http_code}' -u "$BC_AUTH" -X POST -H 'Content-Type: application/json' -d '{}' \
  "$ODATA/BGBWebDemo_SetupDemo?company=$COMPANY")
code=${out##*$'\n'}; body=${out%$'\n'*}
[ "$code" = "200" ] || die "demo setup failed (HTTP $code): $body (is the test app published? run scripts/test-integration.sh)"
ok "$(printf '%s' "$body" | python3 -c 'import sys,json;print(json.load(sys.stdin)["value"])')"
echo
echo "Web client: ${WEB_URL}   user $SALES_USER / $SALES_PASSWORD   (admin: ${BC_AUTH%%:*} / ${BC_AUTH#*:})"
