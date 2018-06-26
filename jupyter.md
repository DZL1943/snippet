# jupyter

```bash
function install_jupyter()
{
    pip install jupyter
    jupyter notebook --generate-config  # ~/.jupyter/jupyter_notebook_config.py
    #jupyter notebook password

    pip install jupyterthemes
    jt -t monokai -f source -fs 12

    pip install bash_kernel
    python -m bash_kernel.install
    jupyter notebook --no-browser --allow-root --ip='*' --port=8888 --notebook-dir=/home
}
```
