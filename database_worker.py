from PySide6.QtCore import QThread, Signal
import psycopg2
from Data_Base_Connection import load_config

class DatabaseWorker(QThread):
    finished = Signal(bool, str)  # success, message
    data_fetched = Signal(bool, list, str) 
    operation_finished = Signal(bool, str, int) # success, message, rows_affected 
    def __init__(self, query, params=None, fetch=False):
        super().__init__()
        self.query = query
        self.params = params # for INSERT and DELETE queries
        self.fetch = fetch # for SELECT queries 
        self.rows_affected = 0 # for DELETE Queries (errormsg if 0 rows are deleted)
        self.config = load_config()  
    
    def run(self):
        try:
            conn = psycopg2.connect(
                host=self.config["host"],
                database=self.config["database"],
                user=self.config["username"],
                password=self.config["password"],
                port=self.config["port"]
            )
            cursor = conn.cursor()
            cursor.execute(self.query, self.params)

            if self.fetch:
                rows = cursor.fetchall()
                self.data_fetched.emit(True, rows, "")
            else:
                self.rows_affected = cursor.rowcount
                conn.commit()
                self.operation_finished.emit(True, "Success !", self.rows_affected)

            cursor.close()
            conn.close()
            
        except Exception as e:
            if self.fetch:
                self.data_fetched.emit(False, [], f"Error: {str(e)}")
            self.finished.emit(False, f"Error: {str(e)}")
            self.operation_finished.emit(False, str(e), 0)