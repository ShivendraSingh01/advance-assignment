def call() {
    def systemPython = sh(
        script: 'command -v python3 || command -v python || true',
        returnStdout: true
    ).trim()

    if (!systemPython) {
        error 'Python was not found. Install python3 and python3-pip on the Jenkins agent.'
    }

    sh """
        "${systemPython}" -m venv .venv || {
            echo "Could not create Python virtual environment."
            echo "Install python3-venv and python3-pip on the Jenkins agent."
            exit 1
        }
    """

    env.PYTHON_BIN = '.venv/bin/python'
    sh '"${PYTHON_BIN}" -m pip --version'
    echo "[churn-app] Using Python: ${env.PYTHON_BIN}"
}
