# Web CI runner compatibility

GitHub Actions mapped `ubuntu-latest` to Ubuntu 26.04. The locked Playwright
1.51.0 browser installer rejects that image, so the job stops before any
tests or build. The first observed failure is recorded in the
[PR check](https://github.com/JaysonAlbert/Picsew/actions/runs/45735673158).

Pin the Web Test and Build job to `ubuntu-24.04`, which has a dependency
recipe in the locked Playwright package. Keep the browser matrix, package lock,
test commands, and production deployment steps as they are. Review the runner
pin when updating Playwright or the GitHub Actions image.

Validate the YAML locally and require the PR job to install both browsers,
run the repository checks, and build the Web bundle before merging.
