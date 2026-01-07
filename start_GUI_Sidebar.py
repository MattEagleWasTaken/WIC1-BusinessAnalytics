from PySide6.QtWidgets import QApplication
from Sidebar import MainWindow
import sys
from Data_Base_Connection import prepare_database

"""run this code to open the GUI"""

# Prepare the database before showing GUI
try:    
    prepare_database()
except Exception as e:
    print(f"Database connection failed! maybe the user_login_config.json is wrong? {e}")

app = QApplication(sys.argv)

window = MainWindow(app)
window.show()

app.exec()
