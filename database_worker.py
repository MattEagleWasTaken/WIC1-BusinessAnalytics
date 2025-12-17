from PySide6.QtCore import QThread, Signal
import psycopg2
from Data_Base_Connection import load_config

class DatabaseWorker(QThread):
    finished = Signal(bool, str)  # success, message
    data_fetched = Signal(bool, list, str) 
    def __init__(self, query, params=None, fetch=False):
        super().__init__()
        self.query = query
        self.params = params # for INSERT and DELETE queries
        self.fetch = fetch # for SELECT queries 
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
                conn.commit()
                self.finished.emit(True, "Data saved succesfully!")

            cursor.close()
            conn.close()
            
        except Exception as e:
            if self.fetch:
                self.data_fetched.emit(False, [], f"Error: {str(e)}")
            self.finished.emit(False, f"Error: {str(e)}")