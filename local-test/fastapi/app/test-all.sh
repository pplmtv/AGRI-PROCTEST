# test-all.sh
#!/bin/bash

# ----------------------------
# how to use:
#   current directory should be agri-poctest
#   chmod +x local-test/fastapi/app/test-all.sh
#   local-test/fastapi/app/test-all.sh
# ----------------------------

local-test/fastapi/app/pre_deploy_security_check.sh
local-test/fastapi/app/farmer_flow.sh
local-test/fastapi/app/family_flow.sh
local-test/fastapi/app/admin_flow.sh
local-test/fastapi/app/pre_deploy_security_check.sh