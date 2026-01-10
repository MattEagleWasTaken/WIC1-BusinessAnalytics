# Author: Matthias Fischer (Matriculation Number: 3013822)

# This application was fully developed by the author.
# The author is responsible for the complete implementation.

from PySide6.QtCore import QThread, Signal
import psycopg2
from Data_Base_Connection import load_config

class DatabaseWorker(QThread):
    """ Handles the Connection between DB and GUI via Threading for a responsive GUI"""

    # Different Signals for different Querys 
    finished = Signal(bool, str)  # [INSERT] success, message
    data_fetched = Signal(bool, list, str) # [SELECT] success, data, message
    operation_finished = Signal(bool, str, int) # [DELETE] success, message, rows_affected 

    def __init__(self, query, params=None, fetch=False):
        super().__init__()
        self.query = query
        self.params = params 
        self.fetch = fetch # 
        self.rows_affected = 0 
        self.config = load_config()  
    
    def run(self):
        """gets triggered by worker.start() -> creates new thread.
        connect to the DB & execute the query with the given params"""
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
            self.operation_finished.emit(False, str(e), 5000)