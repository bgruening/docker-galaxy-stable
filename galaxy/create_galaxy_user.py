from scripts.db_shell import *
from galaxy.util.bunch import Bunch
from galaxy.security import GalaxyRBACAgent
from sqlalchemy.orm import sessionmaker
from sqlalchemy import *
import argparse
bunch = Bunch( **globals() )
engine = create_engine('postgres://galaxy:galaxy@localhost:5432/galaxy')
bunch.session = sessionmaker(bind=engine)
# For backward compatibility with "model.context.current"
bunch.context = sessionmaker(bind=engine)

security_agent = GalaxyRBACAgent( bunch )
security_agent.sa_session = sa_session


def add_user(email, password, key=None):
    """
        Add Galaxy User.
        From John https://gist.github.com/jmchilton/4475646
    """
    query = sa_session.query( User ).filter_by( email=email )
    if query.count() > 0:
        return query.first()
    else:
        user = User(email)
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

    parser = argparse.ArgumentParser(description='Create Galaxy Admin User.')

    parser.add_argument("--user", required=True,
                    help="Username, it should be an email address.")
    parser.add_argument("--password", required=True,
                    help="Password.")
    parser.add_argument("--key", help="API-Key.")

    options = parser.parse_args()

    add_user(options.user, options.password, options.key)

