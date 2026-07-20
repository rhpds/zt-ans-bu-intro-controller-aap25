#!/bin/sh
echo "Validating module-10 via Controller as Code" >> /tmp/progress.log

CAC_DIR="/tmp/controller-as-code"
CAC_VENV="/tmp/cac-venv/bin"

# Run CaC in check mode for job templates only
OUTPUT=$("${CAC_VENV}/ansible-playbook" "${CAC_DIR}/configure_controller_staged.yml" -e module=module-10 --check --tags job_templates 2>&1)
RC=$?

if [ $RC -ne 0 ] || echo "$OUTPUT" | grep -qE "changed=[1-9][0-9]*|failed=[1-9][0-9]*|unreachable=[1-9][0-9]*"; then
  echo "FAIL: Install Apache with Survey job template not found or misconfigured."
  echo "Please verify:"
  echo "  - Install Apache with Survey template exists (case-sensitive)"
  echo "  - Survey is enabled with a student_name variable"
  echo "  - Credentials, inventory, project, and playbook are set correctly"
  echo "Remember names are case-sensitive! Please try again."
  exit 1
fi
