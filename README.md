# casadi.github.io

Requires `docker`

1. Clone this repo
2. Run `docker run --rm --volume "$(pwd):/src" -it -p 1313:1313 jgillis/hugo /bin/bash`
3. Choose a mode:
  - **Development**

    Run `develop.sh` for a development mode, i.e. continuously synchronizing and rebuilding the pages. Goto `http://localhost:1313` in your browser to see the pages being served.

  - **Deploy**

    Run `build.sh` to build the website with the generated files placed in `public/`.
