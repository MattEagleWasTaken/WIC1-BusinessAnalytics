import os 
from PySide6.QtGui import QDoubleValidator, QIntValidator, QPixmap
from PySide6.QtWidgets import QDateEdit, QHBoxLayout, QWidget, QVBoxLayout, QLabel, QLineEdit, QPushButton, QFormLayout
from PySide6.QtCore import Signal, QDate, Qt

class HomePage(QWidget):
    # Signal um Daten an Hauptfenster zu senden
    data_changed = Signal(dict)
    status_message = Signal(str, int)
    
    def __init__(self):
        super().__init__()
        self.base_path = os.path.dirname(os.path.abspath(__file__)) 
        self.image_path = os.path.join(self.base_path, "Images")
        self.setup_ui()
        self.data = {}  # Temporärer Datenspeicher
    
    def create_header(self, title):
        header_layout = QHBoxLayout()
        
        
        title_label = QLabel(title)
        title_label.setStyleSheet("""
            QLabel {
                font-size: 24px;
                font-weight: bold;
                color: #0073B9;
            }
        """)
        
        # Bild rechts
        image_label = QLabel()
        pixmap = QPixmap(os.path.join(self.image_path, "Header.png"))
        scaled_pixmap = pixmap.scaled(100, 100, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)
        image_label.setPixmap(scaled_pixmap)
        
        header_layout.addWidget(title_label)
        header_layout.addStretch()  # Platz zwischen Titel und Bild
        header_layout.addWidget(image_label)
        
        return header_layout

    def setup_ui(self):
        main_layout = QVBoxLayout()
                # Header hinzufügen
        header = self.create_header("Home Page")
        main_layout.addLayout(header)
        
        # Trennlinie (optional)
        separator = QLabel()
        separator.setStyleSheet("QLabel { border-bottom: 2px solid #bdc3c7; }")
        separator.setFixedHeight(2)
        main_layout.addWidget(separator)
        main_layout.addSpacing(20)
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
        
        main_layout.addLayout(form_layout)
        main_layout.addWidget(save_btn)
        main_layout.addStretch()
        
        self.setLayout(main_layout)


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


class GradePage(QWidget):
    # Send Data to the MainWindow via Signals
    data_changed = Signal(dict)
    status_message = Signal(str, int)
    def __init__(self):
        super().__init__()
        self.base_path = os.path.dirname(os.path.abspath(__file__)) 
        self.image_path = os.path.join(self.base_path, "Images")
        self.setup_ui()
        self.data = {}  # Temporärer Datenspeicher
    
    def create_header(self, title):
        header_layout = QHBoxLayout()
        
        
        title_label = QLabel(title)
        title_label.setStyleSheet("""
            QLabel {
                font-size: 24px;
                font-weight: bold;
                color: #0073B9;
            }
        """)
        
        # Bild rechts
        image_label = QLabel()
        pixmap = QPixmap(os.path.join(self.image_path, "Header.png"))
        scaled_pixmap = pixmap.scaled(100, 100, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)
        image_label.setPixmap(scaled_pixmap)
        
        header_layout.addWidget(title_label)
        header_layout.addStretch()  # Platz zwischen Titel und Bild
        header_layout.addWidget(image_label)
        
        return header_layout

    def setup_ui(self):
        layout = QVBoxLayout()
        
        # Header hinzufügen
        header = self.create_header("Grade Entry")
        layout.addLayout(header)
        
        # Trennlinie (optional)
        separator = QLabel()
        separator.setStyleSheet("QLabel { border-bottom: 2px solid #bdc3c7; }")
        separator.setFixedHeight(2)
        layout.addWidget(separator)
        layout.addSpacing(20)


        form_layout = QFormLayout()
        
        self.student_input = QLineEdit()
        self.exam_input = QLineEdit()
        self.grade_input = QLineEdit()
        
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


class StudentPage(QWidget):
    # Signal um Daten an Hauptfenster zu senden
    data_changed = Signal(dict)
    status_message = Signal(str, int)
    
    def __init__(self):
        super().__init__()
        self.base_path = os.path.dirname(os.path.abspath(__file__)) 
        self.image_path = os.path.join(self.base_path, "Images")
        self.setup_ui()
        self.data = {}  # Temporärer Datenspeicher
    
    def create_header(self, title):
        header_layout = QHBoxLayout()
        
        
        title_label = QLabel(title)
        title_label.setStyleSheet("""
            QLabel {
                font-size: 24px;
                font-weight: bold;
                color: #0073B9;
            }
        """)
        
        # Bild rechts
        image_label = QLabel()
        pixmap = QPixmap(os.path.join(self.image_path, "Header.png"))
        scaled_pixmap = pixmap.scaled(100, 100, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)
        image_label.setPixmap(scaled_pixmap)
        
        header_layout.addWidget(title_label)
        header_layout.addStretch()  # Platz zwischen Titel und Bild
        header_layout.addWidget(image_label)
        
        return header_layout

    def setup_ui(self):
        main_layout = QVBoxLayout()
                # Header hinzufügen
        header = self.create_header("Student Entry")
        main_layout.addLayout(header)
        
        # Trennlinie (optional)
        separator = QLabel()
        separator.setStyleSheet("QLabel { border-bottom: 2px solid #bdc3c7; }")
        separator.setFixedHeight(2)
        main_layout.addWidget(separator)
        main_layout.addSpacing(20)
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
        
        main_layout.addLayout(form_layout)
        main_layout.addWidget(save_btn)
        main_layout.addStretch()
        
        self.setLayout(main_layout)


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
            'name': f"{self.first_name_input.text()} {self.last_name_input.text()}",
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


class ExamPage(QWidget):
    # Signal um Daten an Hauptfenster zu senden
    data_changed = Signal(dict)
    status_message = Signal(str, int)
    
    def __init__(self):
        super().__init__()
        self.base_path = os.path.dirname(os.path.abspath(__file__)) 
        self.image_path = os.path.join(self.base_path, "Images")
        self.setup_ui()
        self.data = {}  # Temporärer Datenspeicher
    
    def create_header(self, title):
        header_layout = QHBoxLayout()
        
        
        title_label = QLabel(title)
        title_label.setStyleSheet("""
            QLabel {
                font-size: 24px;
                font-weight: bold;
                color: #0073B9;
            }
        """)
        
        # Bild rechts
        image_label = QLabel()
        pixmap = QPixmap(os.path.join(self.image_path, "Header.png"))
        scaled_pixmap = pixmap.scaled(100, 100, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)
        image_label.setPixmap(scaled_pixmap)
        
        header_layout.addWidget(title_label)
        header_layout.addStretch()  # Platz zwischen Titel und Bild
        header_layout.addWidget(image_label)
        
        return header_layout

    def setup_ui(self):
        main_layout = QVBoxLayout()
                # Header hinzufügen
        header = self.create_header("Exam Entry")
        main_layout.addLayout(header)
        
        # Trennlinie (optional)
        separator = QLabel()
        separator.setStyleSheet("QLabel { border-bottom: 2px solid #bdc3c7; }")
        separator.setFixedHeight(2)
        main_layout.addWidget(separator)
        main_layout.addSpacing(20)
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
        
        main_layout.addLayout(form_layout)
        main_layout.addWidget(save_btn)
        main_layout.addStretch()
        
        self.setLayout(main_layout)


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


class StatsPage(QWidget):
    # Signal um Daten an Hauptfenster zu senden
    data_changed = Signal(dict)
    status_message = Signal(str, int)
    
    def __init__(self):
        super().__init__()
        self.base_path = os.path.dirname(os.path.abspath(__file__)) 
        self.image_path = os.path.join(self.base_path, "Images")
        self.setup_ui()
        self.data = {}  # Temporärer Datenspeicher
    
    def create_header(self, title):
        header_layout = QHBoxLayout()
        
        
        title_label = QLabel(title)
        title_label.setStyleSheet("""
            QLabel {
                font-size: 24px;
                font-weight: bold;
                color: #0073B9;
            }
        """)
        
        # Bild rechts
        image_label = QLabel()
        pixmap = QPixmap(os.path.join(self.image_path, "Header.png"))
        scaled_pixmap = pixmap.scaled(100, 100, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)
        image_label.setPixmap(scaled_pixmap)
        
        header_layout.addWidget(title_label)
        header_layout.addStretch()  # Platz zwischen Titel und Bild
        header_layout.addWidget(image_label)
        
        return header_layout

    def setup_ui(self):
        main_layout = QVBoxLayout()
                # Header hinzufügen
        header = self.create_header("Statistics")
        main_layout.addLayout(header)
        
        # Trennlinie (optional)
        separator = QLabel()
        separator.setStyleSheet("QLabel { border-bottom: 2px solid #bdc3c7; }")
        separator.setFixedHeight(2)
        main_layout.addWidget(separator)
        main_layout.addSpacing(20)
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
        
        main_layout.addLayout(form_layout)
        main_layout.addWidget(save_btn)
        main_layout.addStretch()
        
        self.setLayout(main_layout)


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