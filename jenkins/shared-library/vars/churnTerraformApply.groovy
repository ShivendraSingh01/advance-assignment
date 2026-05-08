def call(String environment) {
    sh """
        terraform -chdir=infra/terraform apply -input=false -auto-approve ../../reports/tfplan-${environment}.out
        terraform -chdir=infra/terraform output
    """
}
