build-ts:
    cd src/frontend/src/frontend/ts  && tsc

start-frontend:
    cd src/frontend/src/frontend/ts && tsc
    cd src/frontend && gleam run -m lustre/dev start

start-backend:
    cd src/backend && gleam run


[confirm("This will delete all builds and dependencies. Continue?")]
clean: 
    rm -r src/backend/build
    rm -r src/frontend/build
    rm -r src/shared/build

install:
    echo "Installing shared library dependencies"
    cd src/shared && gleam deps download
    echo "Installing frontend dependencies"
    cd src/frontend && gleam deps download
    echo "Installing backend dependencies"
    cd src/backend && gleam deps download
