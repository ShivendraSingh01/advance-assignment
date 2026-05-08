def call(String scriptPath, String args = '') {
    def command = args?.trim() ? "sh ${scriptPath} ${args}" : "sh ${scriptPath}"
    echo "[churn-app] Running ${command}"
    sh command
}
