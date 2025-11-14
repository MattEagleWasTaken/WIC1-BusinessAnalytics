from PySide6.QtWidgets import QWidget, QVBoxLayout, QLabel, QLineEdit, QPushButton, QFormLayout
from PySide6.QtCore import Signal

class GradePage(QWidget):
    # Signal um Daten an Hauptfenster zu senden
    data_changed = Signal(dict)
    
    def __init__(self):
        super().__init__()
        self.setup_ui()
        self.data = {}  # Temporärer Datenspeicher
    


    def setup_ui(self):
        layout = QVBoxLayout()
        
        form_layout = QFormLayout()
        
        self.student_input = QLineEdit()
        self.exam_input = QLineEdit()
        self.grade_input = QLineEdit()
        
        form_layout.addRow("Student:", self.student_input)
        form_layout.addRow("Prüfung:", self.exam_input)
        form_layout.addRow("Note:", self.grade_input)
        
        save_btn = QPushButton("Speichern")
        save_btn.clicked.connect(self.save_data)
        
        layout.addLayout(form_layout)
        layout.addWidget(save_btn)
        layout.addStretch()
        
        self.setLayout(layout)
    
    def save_data(self):
        # Daten sammeln
        self.data = {
            'student': self.student_input.text(),
            'exam': self.exam_input.text(),
            'grade': self.grade_input.text()
        }
        # Signal aussenden
        self.data_changed.emit(self.data)
    
    def get_data(self):
        """Gibt aktuelle Formulardaten zurück (auch ungespeicherte)"""
        return {
            'student': self.student_input.text(),
            'exam': self.exam_input.text(),
            'grade': self.grade_input.text()
        }
    
    def clear_form(self):
        """Formular zurücksetzen nach erfolgreichem Speichern"""
        self.student_input.clear()
        self.exam_input.clear()
        self.grade_input.clear()


class StudentPage(QWidget):
    # Signal um Daten an Hauptfenster zu senden
    data_changed = Signal(dict)
    
    def __init__(self):
        super().__init__()
        self.setup_ui()
        self.data = {}  # Temporärer Datenspeicher
    


    def setup_ui(self):
        layout = QVBoxLayout()
        
        form_layout = QFormLayout()
        
        self.first_name_input = QLineEdit()
        self.last_name_input = QLineEdit()
        self.exam_input = QLineEdit()
        self.grade_input = QLineEdit()
        
        form_layout.addRow("Student:", self.student_input)
        form_layout.addRow("Prüfung:", self.exam_input)
        form_layout.addRow("Note:", self.grade_input)
        
        save_btn = QPushButton("Speichern")
        save_btn.clicked.connect(self.save_data)
        
        layout.addLayout(form_layout)
        layout.addWidget(save_btn)
        layout.addStretch()
        
        self.setLayout(layout)
    
    def save_data(self):
        # Daten sammeln
        self.data = {
            'student': self.student_input.text(),
            'exam': self.exam_input.text(),
            'grade': self.grade_input.text()
        }
        # Signal aussenden
        self.data_changed.emit(self.data)
    
    def get_data(self):
        """Gibt aktuelle Formulardaten zurück (auch ungespeicherte)"""
        return {
            'student': self.student_input.text(),
            'exam': self.exam_input.text(),
            'grade': self.grade_input.text()
        }
    
    def clear_form(self):
        """Formular zurücksetzen nach erfolgreichem Speichern"""
        self.student_input.clear()
        self.exam_input.clear()
        self.grade_input.clear()