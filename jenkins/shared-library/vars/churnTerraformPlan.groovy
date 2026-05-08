def call(Map config = [:]) {
    sh """
        terraform -chdir=infra/terraform init -input=false
        terraform -chdir=infra/terraform validate
        terraform -chdir=infra/terraform plan -input=false \
            -var-file=env/${config.environment}.tfvars \
            -var="aws_region=${config.awsRegion}" \
            -var="eks_cluster_name=${config.eksClusterName}" \
            -var="app_name=${config.appName}" \
            -var="eks_version=${config.eksVersion}" \
            -var='node_instance_types=["${config.nodeInstanceType}"]' \
            -out=../../reports/tfplan-${config.environment}.out
    """
}
