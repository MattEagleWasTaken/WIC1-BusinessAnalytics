''' OFFENE TODOS IM FILE ABARBEITEN!!!

ALLGEMEINE TODOS:
[] Kommentare aufräumen
[x] MotherClass einführen
[] delete_btn in allen Pages implementieren
[] Worker implementieren 
[] Settings / PopUp Delete Button 


'''
from database_worker import DatabaseWorker
import os 
from PySide6.QtGui import QDoubleValidator, QIntValidator, QPixmap
from PySide6.QtWidgets import QDateEdit, QHBoxLayout, QWidget, QVBoxLayout, QLabel, QLineEdit, QPushButton, QFormLayout
from PySide6.QtCore import Signal, QDate, Qt

class BasePage(QWidget):
    data_changed = Signal(dict)
    status_message = Signal(str, int)
    
    def __init__(self, title):
        super().__init__()
        self.base_path = os.path.dirname(os.path.abspath(__file__)) 
        self.image_path = os.path.join(self.base_path, "Images")
        self.data = {}  # Temporärer Datenspeicher
        self.title = title
        self.setup_base_ui()


    def setup_base_ui(self):
        self.main_layout = QVBoxLayout()
        
        # Header hinzufügen
        header = self.create_header(self.title)
        self.main_layout.addLayout(header)
        
        # Trennlinie
        separator = QLabel()
        separator.setStyleSheet("QLabel { border-bottom: 2px solid #bdc3c7; }")
        separator.setFixedHeight(2)
        self.main_layout.addWidget(separator)
        self.main_layout.addSpacing(20)
        
        # Content-Bereich (wird von Unterklassen gefüllt)
        self.content_layout = QVBoxLayout()
        self.main_layout.addLayout(self.content_layout)
        
        self.setLayout(self.main_layout)
    
    def create_header(self, title):
        """Erstellt den Header mit Titel und Bild"""
        header_layout = QHBoxLayout()
        
        title_label = QLabel(title)
        title_label.setStyleSheet("""
            QLabel {
                font-size: 24px;
                font-weight: bold;
                color: #0073B9;
            }
        """)
        
        image_label = QLabel()
        pixmap = QPixmap(os.path.join(self.image_path, "Header.png"))
        scaled_pixmap = pixmap.scaled(100, 100, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)
        image_label.setPixmap(scaled_pixmap)
        
        header_layout.addWidget(title_label)
        header_layout.addStretch()
        header_layout.addWidget(image_label)
        
        return header_layout
    
    def setup_ui(self):
        """Has to be implemented by subclass"""
        raise NotImplementedError("Unterklassen müssen setup_ui() implementieren")
    
    def save_data(self):
        """Has to be implemented by subclass"""
        raise NotImplementedError("Unterklassen müssen save_data() implementieren")
    
    def get_data(self):
        """Has to be implemented by subclass"""
        raise NotImplementedError("Unterklassen müssen get_data() implementieren")
    
    def clear_form(self):
        """Has to be implemented by subclass"""
        raise NotImplementedError("Unterklassen müssen clear_form() implementieren")


class HomePage(BasePage):
    
    def __init__(self):
        super().__init__("TODO: Home Page & Settings")
        self.setup_ui()


    def setup_ui(self):
        form_layout = QFormLayout()
        
        name_layout = QHBoxLayout()
        self.first_name_input = QLineEdit()
        self.first_name_input.setPlaceholderText("Firstname")
        self.last_name_input = QLineEdit()
        self.last_name_input.setPlaceholderText("Lastname")
        name_layout.addWidget(self.first_name_input)
        name_layout.addWidget(self.last_name_input)

        form_layout.addRow("Name:", name_layout)

        self.birth_date_input = QDateEdit()
        self.birth_date_input.setDisplayFormat("dd.MM.yyyy")
        self.birth_date_input.setDate(QDate.currentDate())
        self.birth_date_input.setCalendarPopup(True)
        
        self.matriculation_no_input = QLineEdit()
        matriculation_validator = QIntValidator(0, 999999999)
        self.matriculation_no_input.setValidator(matriculation_validator)

        form_layout.addRow("Date of Birth:", self.birth_date_input)
        form_layout.addRow("Matriculation Number:", self.matriculation_no_input)



        save_btn = QPushButton("Save")
        save_btn.clicked.connect(self.save_data)
        
        self.content_layout.addLayout(form_layout)
        self.content_layout.addWidget(save_btn)
        self.content_layout.addStretch()
        


    def save_data(self):
        if not self.first_name_input.text().strip():
            self.status_message.emit("Please enter a firstname", 2000)
            return
        if not self.last_name_input.text().strip():
            self.status_message.emit("Please enter a lastname", 2000)
            return
        if not self.matriculation_no_input.text().strip():
            self.status_message.emit("Please enter a matriculation number", 2000)
            return

        self.data = {
            'first_name': self.first_name_input.text(),
            'last_name': self.last_name_input.text(),
            'birth_date': self.birth_date_input.text(),
            'matriculation_no': self.matriculation_no_input.text()
        }
        # Signal aussenden
        self.data_changed.emit(self.data)
        self.status_message.emit("Student Data saved succesfully!", 2000)
    
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


class GradePage(BasePage):

    def __init__(self):
        super().__init__("Grade Entry")
        self.setup_ui()
    
    def setup_ui(self):
        form_layout = QFormLayout()
        
        self.student_input = QLineEdit()
        self.exam_input = QLineEdit()
        self.grade_input = QLineEdit()
        
        form_layout.addRow("Student:", self.student_input)
        form_layout.addRow("Exam", self.exam_input)
        form_layout.addRow("Grade:", self.grade_input)
        
        save_btn = QPushButton("Save")
        save_btn.clicked.connect(self.save_data)
        
        self.content_layout.addLayout(form_layout)
        self.content_layout.addWidget(save_btn)
        self.content_layout.addStretch()

    
    def save_data(self):
        if not self.student_input.text().strip():
            self.status_message.emit("Please select a student", 2000)
            return
        if not self.exam_input.text().strip():
            self.status_message.emit("Please select an exam", 2000)
            return
        if not self.student_input.text().strip():
            self.status_message.emit(f"Please enter a grade", 2000)
            return
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


class StudentPage(BasePage):
    # Signal um Daten an Hauptfenster zu senden
    data_changed = Signal(dict)
    status_message = Signal(str, int)
    
    def __init__(self):
        super().__init__("Student Entry")
        self.setup_ui()

    def setup_ui(self):
        form_layout = QFormLayout()
        
        name_layout = QHBoxLayout()
        self.first_name_input = QLineEdit()
        self.first_name_input.setPlaceholderText("Firstname")
        self.last_name_input = QLineEdit()
        self.last_name_input.setPlaceholderText("Lastname")
        name_layout.addWidget(self.first_name_input)
        name_layout.addWidget(self.last_name_input)

        form_layout.addRow("Name:", name_layout)

        self.birth_date_input = QDateEdit()
        self.birth_date_input.setDisplayFormat("dd.MM.yyyy")
        self.birth_date_input.setDate(QDate.currentDate())
        self.birth_date_input.setCalendarPopup(True)
        
        self.matriculation_no_input = QLineEdit()
        matriculation_validator = QIntValidator(0, 999999999)
        self.matriculation_no_input.setValidator(matriculation_validator)

        form_layout.addRow("Date of Birth:", self.birth_date_input)
        form_layout.addRow("Matriculation Number:", self.matriculation_no_input)



        save_btn = QPushButton("Save")
        save_btn.clicked.connect(self.save_data)
        
        self.content_layout.addLayout(form_layout)
        self.content_layout.addWidget(save_btn)
        self.content_layout.addStretch()
        



    def save_data(self):
        if not self.first_name_input.text().strip():
            self.status_message.emit("Please enter a firstname", 2000)
            return
        if not self.last_name_input.text().strip():
            self.status_message.emit("Please enter a lastname", 2000)
            return
        if not self.matriculation_no_input.text().strip():
            self.status_message.emit("Please enter a matriculation number", 2000)
            return

        self.data = {
            'first_name': self.first_name_input.text(),
            'last_name': self.last_name_input.text(),
            # 'name': f"{self.first_name_input.text()} {self.last_name_input.text()}",
            'birth_date': self.birth_date_input.text(),
            'matriculation_no': self.matriculation_no_input.text()
        }
        # Signal aussenden
        self.data_changed.emit(self.data)
        self.status_message.emit("Student Data saved succesfully!", 2000)
    
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


class ExamPage(BasePage):

    
    def __init__(self):
        super().__init__("Exam Entry")
        self.setup_ui()
    
   
    def setup_ui(self):
        form_layout = QFormLayout()
              
        self.pnr_input = QLineEdit()
        self.pnr_input.setPlaceholderText("Exam Number")

        self.exam_title_input = QLineEdit()
        self.exam_title_input.setPlaceholderText("Exam title")

        self.exam_date_input = QDateEdit()
        self.exam_date_input.setDisplayFormat("dd.MM.yyyy")
        self.exam_date_input.setCalendarPopup(True)


        #TODO: Das könnte auch ein Dropdown sein? -> Mega Fehleranfällig
        self.semester_input = QLineEdit()
        self.semester_input.setPlaceholderText("Semester")
        semester_validator = QIntValidator(0,7)
        self.semester_input.setValidator(semester_validator)

        #TODO: Auch das könnte ein Dropdown sein?! -> mega fehleranfällig
        self.study_program_input = QLineEdit()
        self.study_program_input.setPlaceholderText("Lastname")


        form_layout.addRow("PNr:", self.pnr_input)
        form_layout.addRow("Title:", self.exam_title_input)
        form_layout.addRow("Date:", self.exam_date_input)
        form_layout.addRow("Semester:", self.semester_input)
        form_layout.addRow("Study program:", self.study_program_input)
        
        
        save_btn = QPushButton("Save")
        save_btn.clicked.connect(self.save_data)

        delete_btn = QPushButton("Delete")
        delete_btn.clicked.connect(self.delete_data)
        
        self.content_layout.addLayout(form_layout)
        self.content_layout.addWidget(save_btn)
        self.content_layout.addStretch()



    def save_data(self):
        if not self.pnr_input.text().strip():
            self.status_message.emit("Please enter an exam number", 2000)
            return
        if not self.exam_title_input.text().strip():
            self.status_message.emit("Please enter an exam title", 2000)
            return
        if not self.exam_date_input.text().strip():
            self.status_message.emit("Please enter an exam date", 2000)
            return
        if not self.semester_input.text().strip():
            self.status_message.emit("Please select a semester", 2000) #TODO: 'Select' oder 'Enter' je nach Dropdown oder nicht
            return
        if not self.study_program_input.text().strip(): #
            self.status_message.emit("Please select a study program", 2000) #TODO: 'Select' oder 'Enter' je nach Dropdown oder nicht
            return

        self.data = {
            'pnr': self.pnr_input.text(),
            'exam_title': self.exam_title_input.text(),
            'exam_date': self.exam_date_input.text(),
            'semester': self.semester_input.text(),
            'study_program': self.study_program_input.text()
        }
        # Signal aussenden
        self.data_changed.emit(self.data)
        self.status_message.emit("Student Data saved succesfully!", 2000)
    
    def get_data(self):
        """Gibt aktuelle Formulardaten zurück (auch ungespeicherte)"""
        return {
            'first_name': self.first_name_input.text(),
            'last_name': self.last_name_input.text(),
            'birth_date': self.birth_date_input.text(),
            'matriculation_no': self.matriculation_no_input.text()
        }
    
    def delete_data(self):
        if not self.pnr_input.text().strip():
            self.status_message.emit("Please enter an exam number to delete it", 2000) #TODO: Entweder so, oder separat aus nem Dropdown auswählen. 
            return
        
        

    def clear_form(self):
        """Formular zurücksetzen nach erfolgreichem Speichern"""
        self.first_name_input.clear()
        self.last_name_input.clear()
        self.birth_date_input.clear()
        self.matriculation_no_input.clear()


class StatsPage(BasePage):
    
    def __init__(self):
        super().__init__("Statistics")
        self.setup_ui()

    def setup_ui(self):

        form_layout = QFormLayout()
        
        name_layout = QHBoxLayout()
        self.first_name_input = QLineEdit()
        self.first_name_input.setPlaceholderText("Firstname")
        self.last_name_input = QLineEdit()
        self.last_name_input.setPlaceholderText("Lastname")
        name_layout.addWidget(self.first_name_input)
        name_layout.addWidget(self.last_name_input)

        form_layout.addRow("Name:", name_layout)

        self.birth_date_input = QDateEdit()
        self.birth_date_input.setDisplayFormat("dd.MM.yyyy")
        self.birth_date_input.setDate(QDate.currentDate())
        self.birth_date_input.setCalendarPopup(True)
        
        self.matriculation_no_input = QLineEdit()
        matriculation_validator = QIntValidator(0, 999999999)
        self.matriculation_no_input.setValidator(matriculation_validator)

        form_layout.addRow("Date of Birth:", self.birth_date_input)
        form_layout.addRow("Matriculation Number:", self.matriculation_no_input)



        save_btn = QPushButton("Save")
        save_btn.clicked.connect(self.save_data)
        
        self.content_layout.addLayout(form_layout)
        self.content_layout.addWidget(save_btn)
        self.content_layout.addStretch()



    def save_data(self):
        if not self.first_name_input.text().strip():
            self.status_message.emit("Please enter a firstname", 2000)
            return
        if not self.last_name_input.text().strip():
            self.status_message.emit("Please enter a lastname", 2000)
            return
        if not self.matriculation_no_input.text().strip():
            self.status_message.emit("Please enter a matriculation number", 2000)
            return

        self.data = {
            'first_name': self.first_name_input.text(),
            'last_name': self.last_name_input.text(),
            'birth_date': self.birth_date_input.text(),
            'matriculation_no': self.matriculation_no_input.text()
        }
        # Signal aussenden
        self.data_changed.emit(self.data)
        self.status_message.emit("Student Data saved succesfully!", 2000)
    
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