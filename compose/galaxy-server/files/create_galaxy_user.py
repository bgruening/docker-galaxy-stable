#!/usr/bin/env python
import sys
sys.path.insert(1,'/galaxy')
sys.path.insert(1,'/galaxy/lib')

from galaxy.model import User, APIKeys
from galaxy.model.mapping import init
from galaxy.model.orm.scripts import get_config
import argparse

def add_user(sa_session, security_agent, email, password, key=None, username="admin"):
    """
        Add Galaxy User.
        From John https://gist.github.com/jmchilton/4475646
    """
    query = sa_session.query( User ).filter_by( email=email )
    if query.count() > 0:
        return query.first()
    else:
        User.use_pbkdf2 = False
        user = User(email)
        user.username = username
        user.set_password_cleartext(password)
        sa_session.add(user)
        sa_session.flush()

        security_agent.create_private_user_role( user )
        if not user.default_permissions:
            security_agent.user_set_default_permissions( user, history=True, dataset=True )

        if key is not None:
            api_key = APIKeys()
            api_key.user_id = user.id
            api_key.key = key
            sa_session.add(api_key)
            sa_session.flush()
        return user


if __name__ == "__main__":
    db_url = get_config(sys.argv, use_argparse=False)['db_url']

    parser = argparse.ArgumentParser(description='Create Galaxy Admin User.')

    parser.add_argument("--user", required=True,
                    help="Username, it should be an email address.")
    parser.add_argument("--password", required=True,
                    help="Password.")
    parser.add_argument("--key", help="API-Key.")
    parser.add_argument("--username", default="admin",
                    help="The public username. Public names must be at least three characters in length and contain only lower-case letters, numbers, and the '-' character.")
    parser.add_argument('args', nargs=argparse.REMAINDER)

    options = parser.parse_args()

    mapping = init('/tmp/', db_url)
    sa_session = mapping.context
    security_agent = mapping.security_agent

    add_user(sa_session, security_agent, options.user, options.password, key=options.key, username=options.username)