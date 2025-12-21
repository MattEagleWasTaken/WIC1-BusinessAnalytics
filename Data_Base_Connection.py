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
    cur = conn.cursor() # Create a cursor to execute SQL commands
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


def create_tables(config):
    """
    Create the 'student', 'exam', and 'grade' tables in the target database.
    Includes primary keys, foreign keys, and sequences as per your schema.

    Args:
        config (dict): PostgreSQL login configuration including 'database'.
    """
    # Connect to the target database where tables should be created
    conn = psycopg2.connect(
        dbname=config["database"],
        user=config["username"],
        password=config["password"],
        host=config["host"],
        port=config["port"]
    )
    conn.autocommit = True  # Each CREATE TABLE statement is executed immediately
    cur = conn.cursor()

    try:
        # Create student table
        cur.execute("""
            CREATE TABLE IF NOT EXISTS public.student (
                matriculation_number VARCHAR(20) PRIMARY KEY,
                first_name VARCHAR(50) NOT NULL,
                last_name VARCHAR(50) NOT NULL,
                date_of_birth DATE NOT NULL
            );
        """)

        # Create exam table
        cur.execute("""
            CREATE TABLE IF NOT EXISTS public.exam (
                pnr VARCHAR(20) PRIMARY KEY,
                title VARCHAR(100) NOT NULL,
                exam_date DATE NOT NULL,
                semester VARCHAR(20),
                degree_program VARCHAR(100)
            );
        """)

        # Create grade table
        cur.execute("""
            CREATE TABLE IF NOT EXISTS public.grade (
                id SERIAL PRIMARY KEY,
                matriculation_number VARCHAR(20) NOT NULL,
                pnr VARCHAR(20) NOT NULL,
                grade NUMERIC(3,1),
                grade_date DATE DEFAULT CURRENT_DATE NOT NULL,
                CONSTRAINT grade_grade_check CHECK (grade >= 1.0 AND grade <= 6.0),
                CONSTRAINT grade_student_fkey FOREIGN KEY (matriculation_number)
                    REFERENCES public.student(matriculation_number)
                    ON DELETE CASCADE,
                CONSTRAINT grade_exam_fkey FOREIGN KEY (pnr)
                    REFERENCES public.exam(pnr)
                    ON DELETE CASCADE,
                CONSTRAINT grade_unique_student_exam UNIQUE (matriculation_number, pnr)
            );
        """)

        print("Tables 'student', 'exam', and 'grade' created successfully.")
    finally:
        cur.close()
        conn.close()


def prepare_database(config_path: str = "user_login_config.json"):
    """
    This is the only function the GUI needs to call.
    It will:
        1. Load config
        2. Connect to postgres server
        3. Check if the target database exists
        4. Create database + tables if missing
    """
    config = load_config(config_path)
    db_name = config["database"]

    # Print config without password for security
    safe_config = {k: v for k, v in config.items() if k != "password"}
    print("Loaded configuration (password hidden):")
    print(safe_config)

    # Connect to postgres admin DB
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
        if database_missing(conn, db_name) == True:
            print(f"Database '{db_name}' does not exist. Creating now...")
            conn.close()  # close old connection before creating DB
            create_database(db_name, config)
            create_tables(config)
        else:
            print(f"Database '{db_name}' already exists. No creation required.")
    finally:
        conn.close()
        print("Connection to server closed.")

