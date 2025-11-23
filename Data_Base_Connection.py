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


def create_database(conn: psycopg2.extensions.connection, db_name: str) -> None:
    """
    Create a new PostgreSQL database with the given name.

    Important:
        - Connection must be made to a different database (commonly 'postgres').
        - CREATE DATABASE cannot be run inside a transaction block.
        - Autocommit is required for database creation.
    """
    conn.autocommit = True
    cur = conn.cursor()
    try:
        # CREATE DATABASE cannot use parameter substitution, so safely quote
        cur.execute(f'CREATE DATABASE "{db_name}";')
        print(f"Database '{db_name}' created successfully.")
    except psycopg2.Error as e:
        print(f"Error creating database '{db_name}': {e.pgerror if e.pgerror else e}")
    finally:
        cur.close()


def main() -> None:
    """
    Main routine:
        1. Load configuration from JSON file.
        2. Connect to PostgreSQL server's default 'postgres' database.
        3. Check if the target database exists.
        4. If missing, create it.
        5. Close the connection.
    """
    config = load_config()

    db_name = config["database"]

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
        print("Failed to connect to PostgreSQL server. Check your credentials and server status.")
        print("Detailed error:", e)
        return

    try:
        # Check if the database exists
        db_missing = database_missing(conn, db_name)
        if db_missing == True:
            print(f"Database '{db_name}' does not exist. Creating now...")
            create_database(conn, db_name)
        else:
            print(f"Database '{db_name}' already exists. No creation required.")
    finally:
        conn.close()
        print("Connection to server closed.")


if __name__ == "__main__":
    main()
