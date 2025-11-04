import os
from PySide6.QtCore import QSize, Qt, QDate, Signal, Slot
from PySide6.QtGui import QIcon, QPixmap
from PySide6.QtWidgets import (QMainWindow, QPushButton, QStatusBar, QLineEdit, QComboBox,
QHBoxLayout, QVBoxLayout, QWidget, QLabel, QSlider, QDateEdit, 
)


class MainWindow(QMainWindow):
    # setup Signal Dictionary for Communication with Backend
    chosen_settings = Signal(dict)

    # setup the main window, the relative image path, the GUI widgets and the main-window-layout
    def __init__(self, app): 
        super().__init__()
        self.app = app
        self.base_path = os.path.dirname(os.path.abspath(__file__)) 
        self.image_path = os.path.join(self.base_path, "Images")
        self.setup_window()
        self.create_widgets()
        self.setup_main_layout()
        #self.initialize_backend()
        self.ai_provider = None
        self.api_key = None
        

    # setup the frame of the main window
    def setup_window(self):
        self.setWindowTitle("NewsProvider")
        self.setFixedSize(800, 600)  
        self.setStatusBar(QStatusBar(self))

    # call functions for every widget used in the main window
    def create_widgets(self):
        self.create_provider_buttons()
        self.create_labels()
        self.create_date_edit()
        self.create_ai_button()
        self.create_go_button()
        self.create_slider()
        self.create_design_element()

    # setup the 4 provider buttons to check which news-provider you would like to get infos from.
    # add matching icons, call the button-style-function and connect the buttons to each clicked-function
    def create_provider_buttons(self):
        '''PROVIDER BUTTONS'''
        self.swr_button = QPushButton(icon=QIcon(os.path.join(self.image_path, "SWR.jpg")))
        self.apply_provider_button_style(self.swr_button)
        self.swr_button.clicked.connect(self.swr_clicked)

        self.tagesschau_button = QPushButton(icon=QIcon(os.path.join(self.image_path, "Tagesschau.jpg")))
        self.apply_provider_button_style(self.tagesschau_button)
        self.tagesschau_button.clicked.connect(self.tagesschau_clicked)

        self.welt_button = QPushButton(icon=QIcon(os.path.join(self.image_path, "Welt.png")))
        self.apply_provider_button_style(self.welt_button)
        self.welt_button.clicked.connect(self.welt_clicked)

        self.good_news_button = QPushButton(icon=QIcon(os.path.join(self.image_path, "Good_news.png")))
        self.apply_provider_button_style(self.good_news_button)
        self.good_news_button.clicked.connect(self.good_news_clicked)

    # setup the calendar/date-edit with a calendar popup to get the news of the selected date (if possible).
    # Default is today
    def create_date_edit(self):
        '''DATE-EDIT'''
        self.date_edit = QDateEdit()
        self.date_edit.setDisplayFormat("dd.MM.yyyy")
        today = QDate.currentDate()
        self.date_edit.setDate(today)
        self.date_edit.setCalendarPopup(True)

    # setup slider to set the desired summary length 
    def create_slider(self):
        '''SLIDER'''
        self.slider = QSlider(Qt.Orientation.Horizontal)
        self.apply_slider_style(self.slider)
        self.slider.valueChanged.connect(self.summary_length_changed)

    # setup every (informative/header) label & show some info at the statusbar when hovering over each label
    def create_labels(self):
        '''LABELS'''
        self.provider_label = QLabel("Set Providers ⓘ")
        self.provider_label.enterEvent = lambda z: self.statusBar().showMessage("Nachrichtenquellen ein-  oder ausschließen. Default: Alle eingeschlossen")
        self.provider_label.leaveEvent = lambda z: self.statusBar().clearMessage()

        self.date_label = QLabel("Set Date ⓘ")
        self.date_label.enterEvent = lambda z: self.statusBar().showMessage("Tag der gewünschten Zusammenfassung wählen.")
        self.date_label.leaveEvent = lambda z: self.statusBar().clearMessage()

        self.slider_label = QLabel("Set Length ⓘ")
        self.slider_label.enterEvent = lambda z: self.statusBar().showMessage("Länge der gewünschten Zusammenfassung wählen. Default sind 2 Sätze pro Artikel")
        self.slider_label.leaveEvent = lambda z: self.statusBar().clearMessage()

    def create_ai_button(self):
        '''AI BUTTON'''
        self.ai_button = QPushButton("AI Settings")
        self.apply_ai_button_style(self.ai_button)
        #self.ai_button.clicked.connect(self.ai_button_clicked)

    # setup the GO! Button, apply it's own style and connect the clicked-function
    def create_go_button(self):
        '''GO BUTTON'''
        #tbd: connection -> new window 
        self.go_button = QPushButton("GO!")
        self.apply_go_button_style(self.go_button)
        #self.go_button.clicked.connect(self.go_button_clicked)
    
    # setup the left-bound design element (just for aesthetic purposes)
    # opens the image into a label with a fixed width of 1/3 of the main window. Crops to set the desired width if necessary
    def create_design_element(self):
        '''DESIGN-ELEMENT'''
        design_path = os.path.join(self.image_path, "Design.jpeg")
        try:
            with open(design_path):
                self.design_label = QLabel()
                pixmap = QPixmap(design_path)
                
                image_width = self.width() // 3
                self.design_label.setFixedWidth(image_width)
                
                scaled_pixmap = pixmap.scaledToWidth(
                image_width, 
                Qt.TransformationMode.SmoothTransformation #smooth zooming/interpolation 
                )

                self.design_label.setPixmap(scaled_pixmap)
            
            self.design_label.setAlignment(Qt.AlignCenter)

        except:
            self.design_label = QLabel("Bild nicht gefunden")

    # setup the main layout with nested layout-functions. 
    # main-layout consists of the design-element on the left and the widgets on the right. 
    def setup_main_layout(self):
        container = QWidget()
        h_layout = QHBoxLayout()
        h_layout.addWidget(self.design_label)

        v_layout_right = self.create_right_v_layout()
        h_layout.addLayout(v_layout_right)
        
        container.setLayout(h_layout)
        self.setCentralWidget(container)

    # setup the nested layout with the widgets on the right starting from the top.
    def create_right_v_layout(self):
        v_layout = QVBoxLayout()

        # the 4 provider buttons are nested in the create buttons layout function.
        '''Provider Area'''
        v_layout.addWidget(self.provider_label)
        v_layout.addLayout(self.create_provider_buttons_layout())
        
        '''Date-Edit Area'''
        v_layout.addWidget(self.date_label)
        v_layout.addWidget(self.date_edit)
    
        '''Slider Area'''
        v_layout.addWidget(self.slider_label)
        v_layout.addWidget(self.slider)

        # the settings-button is placed on the lower left, and the AI settings button on the lower right corner
        '''Go & Settings Button Area'''
        go_layout = QHBoxLayout()
        go_layout.addWidget(self.ai_button)
        go_layout.addStretch(1)  
        go_layout.addWidget(self.go_button)
        v_layout.addLayout(go_layout)

        return v_layout 

    # setup the last nested layout function for the provider buttons.
    def create_provider_buttons_layout(self):
        v_layout = QVBoxLayout()
        
        '''Upper Row'''
        h_layout_1 = QHBoxLayout()
        h_layout_1.addWidget(self.swr_button)
        h_layout_1.addWidget(self.tagesschau_button)
        v_layout.addLayout(h_layout_1)

        '''Lower Row'''
        h_layout_2 = QHBoxLayout()
        h_layout_2.addWidget(self.welt_button)
        h_layout_2.addWidget(self.good_news_button)
        v_layout.addLayout(h_layout_2)

        return v_layout 

    # setup the stylesheet of the provider buttons 
    # Set them as checkable, default is checked, with some more design ideas to make them look good and "clickable"
    def apply_provider_button_style(self, button):
        button.setCheckable(True)
        button.setChecked(True)
        button.setFixedSize(120,120)
        button.setIconSize(QSize(115, 115))
        button.setStyleSheet("""
            QPushButton {
                padding: 0px;
                border: 2px solid #cccccc;
                border-radius: 5px;
            }
            QPushButton:hover {
                border: 2px solid #3daee9;
                background-color: rgba(61, 174, 233, 20);
            }
            QPushButton:pressed {
                border: 3px solid #2980b9;
                background-color: rgba(61, 174, 233, 50);
            }
            QPushButton:checked {
                border: 3px solid #27ae60;
                background-color: rgba(39, 174, 96, 30);
            }
        """)

    # setup the stylesheet for the different looking "GO!" button
    # also make it look good and "clickable"
    def apply_go_button_style(self, button):
       button.setStyleSheet("""
            QPushButton {
                background-color: #00AB66;
            }
            QPushButton:hover {
                border: 2px solid #3daee9;
                background-color: #00AB66;
            }
            QPushButton:pressed {
                border: 3px solid #2980b9;
                background-color: #009257;
            }
        """)

    def apply_ai_button_style(self, button):
        button.setStyleSheet("""QPushButton {
                background-color: #808080;
            }
            QPushButton:hover {
                border: 2px solid #3daee9;
                background-color: #646464;
            }
            QPushButton:pressed {
                border: 3px solid #2980b9;
                background-color: #414141;
            }                            
        """

        )

    # show an infomsg at the statusbar if the user changes the desired providers (every provider buttons_clicked function)
    def swr_clicked(self):
        if self.swr_button.isChecked() == True:
            self.statusBar().showMessage("SWR ausgewählt ✓", 2000)
            return True
        elif self.swr_button.isChecked() == False:
            self.statusBar().showMessage("SWR abgewählt ✕", 2000)
            return False
        else:
            self.statusBar().showMessage("Fehler beim Auswählen der Provider [SWR", 2000)
     
    def welt_clicked(self):
        if self.welt_button.isChecked() == True:
            self.statusBar().showMessage("Welt ausgewählt ✓", 2000)
            return True
        elif self.welt_button.isChecked() == False:
            self.statusBar().showMessage("Welt abgewählt ✕", 2000)
            return False
        else:
            self.statusBar().showMessage("Fehler beim Auswählen der Provider [WELT]", 2000)

    def tagesschau_clicked(self):
        if self.tagesschau_button.isChecked() == True:
            self.statusBar().showMessage("Tagesschau ausgewählt ✓", 2000)
            return True
        elif self.tagesschau_button.isChecked() == False:
            self.statusBar().showMessage("Tagesschau abgewählt ✕", 2000)
            return False
        else:
            self.statusBar().showMessage("Fehler beim Auswählen der Provider [TAGESSCHAU]", 2000)

    def good_news_clicked(self):
        if self.good_news_button.isChecked() == True:
            self.statusBar().showMessage("Good News ausgewählt ✓", 2000)
            return True
        elif self.good_news_button.isChecked() == False:
            self.statusBar().showMessage("Good News abgewählt ✕", 2000)
            return False
        else:
            self.statusBar().showMessage("Fehler beim Auswählen der Provider [Good News]", 2000)
    
    # open up a new window to enter the desired ai provider URL and the api-key.  
    # def ai_button_clicked(self):
    #    self.ai_settings_widget = AiSettings()
    #    self.ai_settings_widget.settings_confirmed.connect(self.update_ai_settings)
    #    self.ai_settings_widget.show()

    # Save ai settings and errorhandling
    def update_ai_settings(self, ai_provider, api_key, model_id):
        self.ai_provider = ai_provider
        self.api_key = api_key
        self.model_id = model_id
        if ai_provider == "":
            ai_provider = "FEHLER: Keine Endpoint-URL angegeben"
            self.statusBar().showMessage(f"Fehler bei der Endpoint-URL", 2000)
        else:    
            self.statusBar().showMessage(f"KI-Provider aktualisiert: {ai_provider}", 2000)

    # change the slider style to make it more intuitive to use
    def apply_slider_style(self, slider):
        slider.setMinimum(1)
        slider.setMaximum(4)
        slider.setTickPosition(QSlider.TickPosition.TicksBelow)
        slider.setTickInterval(1)

    # show an infomsg at the statusbar if the user changes the desired length of the summary
    def summary_length_changed(self, value):
         if value == 1:
              self.statusBar().showMessage("Kurze Zusammenfassung (1 Satz)",2000)
         elif value == 2:
              self.statusBar().showMessage("Mittlere Zusammenfassung (2 Sätze)",2000)
         elif value == 3:
              self.statusBar().showMessage("Längere Zusammenfassung (4 Sätze)",2000)
         elif value == 4:
              self.statusBar().showMessage("Ausführliche Zusammenfassung (6 Sätze)",2000)

    # connect go button 
    #def go_button_clicked(self):
         # TODO: Loading screen, Threading and
        # self.statusBar().showMessage("Artikel werden zusammengefasst... ", 2000)
        # settings = self.get_chosen_settings()

        # self.loading_dialog = LoadingDialog()
        # self.loading_dialog.show()
        
        # self.backend.process_settings(settings)

    # Summarize settings chosen from the User and emit it to the backend
    def get_chosen_settings(self):
        settings = {
            # isChecked returns a bool.
            "swr": self.swr_button.isChecked(), # source_id "4" in News.db 
            "welt": self.welt_button.isChecked(), # source_id "2" in News.db 
            "tagesschau": self.tagesschau_button.isChecked(), # source_id "1" in News.db 
            "good_news":self.good_news_button.isChecked(), # source_id "3" in News.db 
            # returns a String.
            "date": self.date_edit.date().toString("yyyy-MM-dd"),
            # returns an int between 1 and 4.
            # (each Article: 1 = 1 Sentence, 2 = 2 Sentences, 3 = 4 Sentences, 4 = 6 Sentences)
            "length": self.slider.value(),
            # returns the set ai provider and api key 
            "api_key": self.api_key,
            "ai_provider": self.ai_provider,
            "model_id": self.model_id
        }
        self.chosen_settings.emit(settings)
        return settings
    
    
    #def initialize_backend(self):
        self.backend = NewsBackend()
        self.backend.results_available.connect(self.on_results_ready)
        self.backend.processing_finished.connect(self.on_processing_finished) # Für den Loading screen

    # When the results are ready - open the summary window 
    #@Slot(str)
    #def on_results_ready(self, summary):
        self.summary_window = SummaryWindow(results=summary)
        self.summary_window.show()

    # Close Loading Dialog if results are ready. 
    @Slot()
    def on_processing_finished(self):
        if hasattr(self, "loading_dialog") and self.loading_dialog:
            self.loading_dialog.close()
