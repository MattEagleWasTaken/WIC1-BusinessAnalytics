from PySide6.QtWidgets import QApplication
from Sidebar import MainWindow
import sys
from Data_Base_Connection import prepare_database

# Prepare the database before showing GUI
prepare_database()

app = QApplication(sys.argv)

window = MainWindow(app)
window.show()

app.exec()
