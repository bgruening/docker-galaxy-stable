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
      "GALAXY_CONFIG_": "galaxy",
      "GALAXY_UWSGI_CONFIG_": "galaxy_uwsgi"
    }

    # Add values from possible input file if existent
    if context is not None and len(context) > 0:
      new_context.update(context)

    for to in translations.values():
      if to not in new_context:
        new_context[to] = {}

    for key, value in os.environ.items():
      for frm, to in translations.items():
        if key.startswith(frm):
          key = key[len(frm):].lower()
          if key not in new_context[to]:
            new_context[to][key] = value

    return new_context

