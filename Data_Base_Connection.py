import json
import psycopg2
import psycopg2.extensions

def load_config(path: str = "user_login_config.json") -> dict:
    """
    Load the PostgreSQL login configuration from a JSON file.

    The JSON file should contain:
        - username
        - password
        - host
        - port
        - database

    Returns:
        dict with keys as listed above.
    """
    with open(path, "r", encoding="utf-8") as file:
        return json.load(file)


def database_missing(conn: psycopg2.extensions.connection, db_name: str) -> bool:
    """
    Check if the database does NOT exist.

    Returns True if the database is missing, False if it exists.
    """
    cur = conn.cursor()
    try:
        # Execute a query to see if the database exists
        cur.execute("SELECT 1 FROM pg_database WHERE datname = %s;", (db_name,))
        row = cur.fetchone()
        # If fetchone() returns None, the database does not exist
        db_missing = row is None
        return db_missing
    finally:
        # Always close the cursor to free server-side resources
        cur.close()


def create_database(db_name, config):
    # Connect to the default administrative 'postgres' database
    # This connection is needed to create a new database because CREATE DATABASE
    # cannot be run inside a transaction and requires admin privileges.
    conn = psycopg2.connect(
        dbname="postgres",
        user=config["username"],  # Your local PostgreSQL username
        password=config["password"],  # Your local PostgreSQL password
        host=config["host"],  # Usually 'localhost'
        port=config["port"]  # Default PostgreSQL port 5432
    )

    conn.autocommit = True  # Enable autocommit so CREATE DATABASE can execute outside a transaction
    cur = conn.cursor()  # Create a cursor to execute SQL commands

    try:
        # Execute the SQL command to create a new database with the given name
        cur.execute(f"CREATE DATABASE {db_name}")
        print(f"Database '{db_name}' created successfully.")
    finally:
        # Always close cursor and connection to free resources
        cur.close()
        conn.close()


def main() -> None:
    """
    Main program flow:
        1. Load PostgreSQL login configuration from a JSON file.
        2. Connect to the administrative 'postgres' database.
        3. Check if the target database exists.
        4. If missing, create it.
        5. Close connections properly.
    """

    # Load login configuration (username, password, host, port, database)
    config = load_config()

    # Name of the database we want to use/create
    db_name = config["database"]

    # Print loaded config, but hide password for security
    print("Loaded configuration (password hidden):")
    safe_config = {k: v for k, v in config.items() if k != "password"}
    print(safe_config)

    # Connect to the administrative 'postgres' database
    try:
        conn = psycopg2.connect(
            dbname="postgres",
            user=config["username"],
            password=config["password"],
            host=config["host"],
            port=config["port"]
        )
        print("Connected to PostgreSQL server (database 'postgres').")
    except psycopg2.OperationalError as e:
        # Catch errors if connection fails (wrong credentials, server not running)
        print("Failed to connect to PostgreSQL server. Check your credentials and server status.")
        print("Detailed error:", e)
        return  # Exit main if we can't connect

    try:
        # Check if the target database exists
        db_missing = database_missing(conn, db_name)

        # Explicit boolean comparison for readability
        if db_missing == True:
            print(f"Database '{db_name}' does not exist. Creating now...")
            # Close the current connection before creating the database
            conn.close()
            # Call function to create the new database
            create_database(db_name, config)
        else:
            print(f"Database '{db_name}' already exists. No creation required.")
    finally:
        # Ensure the administrative connection is always closed
        conn.close()
        print("Connection to server closed.")


if __name__ == "__main__":
    main()

