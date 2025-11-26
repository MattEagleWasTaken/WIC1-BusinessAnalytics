from PySide6.QtCore import QThread, Signal
import psycopg2

class DatabaseWorker(QThread):
    finished = Signal(bool, str)  # success, message
    
    def __init__(self, query, params=None):
        super().__init__()
        self.query = query
        self.params = params
    
    def run(self):
        try:
            conn = psycopg2.connect(
                host="localhost",
                database="your_db",
                user="your_user",
                password="your_password"
            )
            cursor = conn.cursor()
            cursor.execute(self.query, self.params)
            conn.commit()
            cursor.close()
            conn.close()
            self.finished.emit(True, "Data saved successfully!")
        except Exception as e:
            self.finished.emit(False, f"Error: {str(e)}")