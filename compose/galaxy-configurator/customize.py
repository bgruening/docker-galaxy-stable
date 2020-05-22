import os


def j2_environment_params():
    """ Extra parameters for the Jinja2 Environment
    Add AnsibleCoreFiltersExtension for filters known in Ansible
    like `to_nice_yaml`
    """
    return dict(
        extensions=('jinja2_ansible_filters.AnsibleCoreFiltersExtension',),
    )


def alter_context(context):
    """
    Translates env variables that start with a specific prefix
    and combines them into one dict (like all GALAXY_CONFIG_*
    are stored at galaxy.*).
    Variables that are stored in an input file overwrite
    the input from env.

    TODO: Unit test
    """
    new_context = dict(os.environ)

    translations = {
      "GALAXY_CONFIG_":         "galaxy",
      "GALAXY_UWSGI_CONFIG_":   "galaxy_uwsgi",
      "GALAXY_JOB_METRICS_":    "galaxy_job_metrics",
      "NGINX_CONFIG_":          "nginx",
      "SLURM_CONFIG_":          "slurm",
      "HTCONDOR_GALAXY_":       "htcondor_galaxy",
      "HTCONDOR_MASTER_":       "htcondor_master",
      "HTCONDOR_EXECUTOR_":     "htcondor_executor",
      "PULSAR_CONFIG_":         "pulsar"
    }

    # Add values from possible input file if existent
    if context is not None and len(context) > 0:
        new_context.update(context)

    # Translate string-boolean to Python boolean
    for key, value in new_context.items():
        if not isinstance(value, str):
            continue
        if value.lower() == "true":
            new_context[key] = True
        elif value.lower() == "false":
            new_context[key] = False

    for to in translations.values():
        if to not in new_context:
            new_context[to] = {}

    for key, value in new_context.items():
        for frm, to in translations.items():
            if key.startswith(frm):
                # Format key depending on it being uppercase or not
                # (to cope with different formatings: compare Slurm
                # with Galaxy)
                key = key[len(frm):]
                if key.isupper():
                    key = key.lower()

                new_context[to][key] = value

    context = new_context

    # Set HOST_EXPORT_DIR depending on EXPORT_DIR being absolute or relative
    if "HOST_EXPORT_DIR" not in context and "EXPORT_DIR" in context \
            and "HOST_PWD" in context:
        if context["EXPORT_DIR"].startswith("./"):
            context["HOST_EXPORT_DIR"] = context["HOST_PWD"] \
                                         + context["EXPORT_DIR"][1:]
        else:
            context["HOST_EXPORT_DIR"] = context["EXPORT_DIR"]

    return context
