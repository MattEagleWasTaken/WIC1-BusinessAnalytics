from PySide6.QtWidgets import QHBoxLayout, QWidget, QVBoxLayout, QLabel, QLineEdit, QPushButton, QFormLayout
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
        
        self.student_input = QLineEdit() # TODO: Soll später ein Dropdown aus den angelegten Studierenden sein.
                                         # GGFS first&last name hier gemerged anzeigen
        self.exam_input = QLineEdit() # TODO: Dropdown Menü aus angelegten Exams
        self.grade_input = QLineEdit() # TODO: Errorhandling
        
        form_layout.addRow("Student:", self.student_input)
        form_layout.addRow("Exam", self.exam_input)
        form_layout.addRow("Grade:", self.grade_input)
        
        save_btn = QPushButton("Save")
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
        main_layout = QVBoxLayout()
        
        form_layout = QFormLayout()
        
        name_layout = QHBoxLayout()
        self.first_name_input = QLineEdit()
        self.last_name_input = QLineEdit()
        name_layout.addWidget(QLabel("Vorname:"))
        name_layout.addWidget(self.first_name_input)
        name_layout.addWidget(QLabel("Nachname:"))
        name_layout.addWidget(self.last_name_input)

        form_layout.addRow("Name:", name_layout)

        self.matriculation_no_input = QLineEdit()
        self.birth_date_input = QLineEdit()
        
        form_layout.addRow("Date of Birth:", self.birth_date_input)
        form_layout.addRow("Matriculation Number:", self.matriculation_no_input)
    

        save_btn = QPushButton("Save")
        save_btn.clicked.connect(self.save_data)
        
        main_layout.addLayout(form_layout)
        main_layout.addWidget(save_btn)
        main_layout.addStretch()
        
        self.setLayout(main_layout)
    
    def save_data(self):
        # TODO: Errorhandling - kein Saving wenn falsche Daten eingetragen sind + MSG in Statusbar
        self.data = {
            'first_name': self.first_name_input.text(),
            'last_name': self.last_name_input.text(),
            'birth_date': self.birth_date_input.text(),
            'matriculation_no': self.matriculation_no_input.text()
        }
        # Signal aussenden
        self.data_changed.emit(self.data)
    
    def get_data(self):
        """Gibt aktuelle Formulardaten zurück (auch ungespeicherte)"""
        return {
            'first_name': self.first_name_input.text(),
            'last_name': self.last_name_input.text(),
            'birth_date': self.birth_date_input.text(),
            'matriculation_no': self.matriculation_no_input.text()
        }
    
    def clear_form(self):
        """Formular zurücksetzen nach erfolgreichem Speichern"""
        self.first_name_input.clear()
        self.last_name_input.clear()
        self.birth_date_input.clear()
        self.matriculation_no_input.clear()

        