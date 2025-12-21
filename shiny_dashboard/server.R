server <- function(input, output, session) {
  
  library(DBI)
  library(RPostgres)
  library(jsonlite)
  library(shinyjs)
  library(ggplot2)
  
  
# ---------------- Load DB Credentials ----------------
  db_config <- fromJSON("../user_login_config.json")
  
  con <- dbConnect(
    RPostgres::Postgres(),
    dbname   = db_config$database,
    host     = db_config$host,
    port     = db_config$port,
    user     = db_config$username,
    password = db_config$password
  )
  
# ---------------- Load Student Data ----------------
  students <- dbGetQuery(con, "
    SELECT matriculation_number, first_name, last_name FROM student
  ")
  
  students_sorted_matr <- students[order(students$matriculation_number), ]
  students_sorted_name <- students[order(students$last_name, students$first_name), ]
  students_sorted_name$full_name <- paste(students_sorted_name$first_name,
                                          students_sorted_name$last_name)
  
  name_choices <- c("- not selected -", students_sorted_name$full_name)
  matr_choices <- c("- not selected -", students_sorted_matr$matriculation_number)
  
  
# ============================================================================
# Dynamic Input Row (for "One Student")
# ============================================================================
  output$one_student_filters <- renderUI({
    
    req(input$student_toggle == "One Student")
    
    name_selected <- !is.null(input$name_select) &&
      input$name_select != "- not selected -"
    
    matr_selected <- !is.null(input$matnr_select) &&
      input$matnr_select != "- not selected -"
    
    div(
      style = "display: flex; align-items: flex-start; gap: 20px; margin-top: 20px;",
      
      # ---------------- Student Name ----------------
      if (!matr_selected) {
        selectInput(
          "name_select",
          label = tags$label(
            "Student Name:",
            style = "margin-top: 6px;"
          ),
          choices  = name_choices,
          selected = input$name_select %||% "- not selected -"
        )
      } else {
        div(
          class = "static-text-container",
          style = "margin-top: 0px;",
          
          tags$label(
            "Student Name:",
            style = "margin-top: 6px;"
          ),
          
          div(
            class = "static-text-input",
            style = "margin-top: 5px; box-shadow: 0px 2px 6px rgba(0,0,0,0.2);",
            {
              row <- students_sorted_name[
                students_sorted_name$matriculation_number == input$matnr_select,
              ]
              paste(row$first_name, row$last_name)
            }
          )
        )
      },
      
      # ---------------- Matriculation Number ----------------
      if (!name_selected) {
        selectInput(
          "matnr_select",
          label = tags$label(
            "Matriculation Number:",
            style = "margin-top: 6px;"
          ),
          choices  = matr_choices,
          selected = input$matnr_select %||% "- not selected -"
        )
      } else {
        div(
          class = "static-text-container",
          style = "margin-top: 0px;",
          
          tags$label(
            "Matriculation Number:",
            style = "margin-top: 6px;"
          ),
          
          div(
            class = "static-text-input",
            style = "margin-top: 5px; box-shadow: 0px 2px 6px rgba(0,0,0,0.2);",
            {
              row <- students_sorted_name[
                students_sorted_name$full_name == input$name_select,
              ]
              row$matriculation_number
            }
          )
        )
      },
      
      # ---------------- Reset Button ----------------
      actionButton(
        "reset_filters",
        "Reset Selection",
        class = "reset-btn",
        style = "margin-top:35px; box-shadow: 0px 2px 6px rgba(0,0,0,0.2);"
      )
    )
  })
  
 
# ============================================================================
# Show / Hide Reset Button
# ============================================================================
  observe({
    if (
      (!is.null(input$name_select) && input$name_select != "- not selected -") ||
      (!is.null(input$matnr_select) && input$matnr_select != "- not selected -")
    ) {
      shinyjs::show("reset_filters")
    } else {
      shinyjs::hide("reset_filters")
    }
  })
  
  
# ============================================================================
# Reset all dropdowns
# ============================================================================
  observeEvent(input$reset_filters, {
    updateSelectInput(session, "name_select", selected = "- not selected -")
    updateSelectInput(session, "matnr_select", selected = "- not selected -")
  
    # Set bar plot data to NULL → plot becomes empty
    student_grades_for_plot(NULL)
    
    })
  
# ============================================================================
# All Average Grades of all Students
# ============================================================================
all_student_averages <- dbGetQuery(
  con,
"
SELECT 
    g.matriculation_number,
    AVG(g.grade) AS student_avg
  FROM grade g
  GROUP BY g.matriculation_number
  "
)  

# Mean of all Student averages  
overall_average <- mean(all_student_averages$student_avg, na.rm = TRUE)  

# SD of all Students
overall_sd      <- sd(all_student_averages$student_avg, na.rm = TRUE) 
  
    
# ============================================================================
# All Grades for selected student
# ============================================================================
# empty variable for student plot
student_grades_for_plot <- reactiveVal(NULL)
  
  
output$student_gpa <- renderText({
    
# ---------------- If All Students Mode ------------------------------------------------
  if (input$student_toggle == "All Students") {
    
    if (is.null(all_student_averages) || nrow(all_student_averages) == 0)
      return("-")
    
    # Average grade + SD in smaller font
      return(paste0(round(overall_average, 2), " ± ", round(overall_sd, 2)))  
    }
          
    
    
# ---------------- One Student Mode ---------------------------------------------------    
    req(input$student_toggle == "One Student")
    
    selected_matr <- input$matnr_select
    selected_name <- input$name_select
    
    # Resolve matriculation number
    if (!is.null(selected_matr) && selected_matr != "- not selected -") {
      matr <- selected_matr
    } else if (!is.null(selected_name) && selected_name != "- not selected -") {
      row <- students_sorted_name[students_sorted_name$full_name == selected_name, ]
      matr <- row$matriculation_number
    } else {
      return("-")
    }
    
    # Load grades + exam titles
    student_grades <- dbGetQuery(
      con,
      paste0("
      SELECT g.grade, g.grade_date, e.title AS exam_title
      FROM grade g
      JOIN exam e ON g.pnr = e.pnr
      WHERE g.matriculation_number = '", matr, "'
    ")
    )
    
    # saves grades for student plot
    student_grades_for_plot(student_grades)
    
    # Average Grade Calculation stays unchanged
    if (nrow(student_grades) == 0) return("-")
    
    round(mean(student_grades$grade, na.rm = TRUE), 2)
    
  })
  
 #----- Dynamic Average Grade Text Output-------------------------------------- 
  output$gpa_title <- renderUI({
    title <- if (input$student_toggle == "All Students") {
      HTML("Overall<br>Average Grade")
    } else {
      HTML("Student<br>Average Grade")
    }
    
    h3(
      title,
      style = "
      margin: 0;
      margin-bottom: 10px;
      font-size: 20px;
      font-weight: bold;
      text-align: center;
    "
    )
  })
  
  
# ============================================================================
# Grades horizontal bar plot
# ============================================================================
  output$grades_plot <- renderPlot({
    df <- student_grades_for_plot()
    if (is.null(df) || nrow(df) == 0) return(NULL)
    
    # Assign colors based on grade ranges (4 levels)
    df$color <- with(df, ifelse(grade <= 1.5, "#3c8d40",   # dark green
                                ifelse(grade <= 2.5, "#88c999",   # light green
                                       ifelse(grade <= 3.5, "#f3b173",   # orange
                                              "#e16b6b"))))            # red
    
    # Order exams: best grade (lowest value) on top
    df$exam_title <- factor(df$exam_title, levels = rev(df$exam_title[order(df$grade)]))
    
    # ------------------------------------------------------------
    # Resolve student full name for dynamic title
    # ------------------------------------------------------------
    student_name <- NULL
    
    if (input$student_toggle == "One Student") {
      
      if (!is.null(input$name_select) &&
          input$name_select != "- not selected -") {
        
        student_name <- input$name_select
        
      } else if (!is.null(input$matnr_select) &&
                 input$matnr_select != "- not selected -") {
        
        row <- students_sorted_name[
          students_sorted_name$matriculation_number == input$matnr_select,
        ]
        
        if (nrow(row) == 1) {
          student_name <- row$full_name
        }
      }
    }
    
    
    ggplot(df, aes(x = grade, y = exam_title, fill = color)) +
      geom_col(width = 0.6, color = "black", show.legend = FALSE) +
      # Add grade labels inside the bars
      geom_text(aes(label = grade),
                position = position_stack(vjust = 0.5),
                color = "black",
                size = 5,
                fontface = "bold") +
      # X-axis from 1 (left) to 6 (right) with breaks
      scale_x_continuous(
        breaks = 1:6,
        labels = 1:6,
        expand = expansion(mult = c(0.02, 0.05))
      ) +
      scale_fill_identity() +  # Use actual hex colors
      labs(
        x = "Grade",
        y = "Exam",
        title = if (!is.null(student_name)) {
          paste0("Student Grades Overview – ", student_name)
        } else {
          "Student Grades Overview"
        }
      ) +
      theme_minimal(base_size = 14) +
      theme(
        plot.background  = element_rect(fill = "white", color = NA, linewidth = 0),
        panel.background = element_rect(fill = "white", color = "grey90", linewidth = 1),
        # ------------------------------------------------------------
        # Grid styling (consistent with One Exam histogram)
        # ------------------------------------------------------------
        panel.grid.major.y = element_line(
          color = "grey70",
          linewidth = 0.8
        ),
        panel.grid.major.x = element_line(
          color = "grey80",
          linewidth = 0.6
        ),
        panel.grid.minor = element_blank(),
        plot.title       = element_text(face = "bold", hjust = 0.5, size = 18),
        axis.text        = element_text(face = "bold", color = "black"),
        axis.title       = element_text(face = "bold", size = 14),
        axis.text.x = element_text(face = "plain", color = "black", size = 14),  
        axis.text.y = element_text(face = "plain", color = "black", size = 14)
      )
  })
  
# ============================================================================
# PIE PLOT – Performance distribution of all students
# ============================================================================
  total_students <- nrow(all_student_averages)
  
  output$pie_plot <- renderPlot({
    
    df <- all_student_averages
    
    # Create grade clusters with ranges in labels
    df$cluster <- cut(
      df$student_avg,
      breaks = c(0, 1.5, 2.5, 3.5, 4.1),
      labels = c(
        "Very Good (≤1.5)",
        "Good (1.6–2.5)",
        "Average (2.6–3.5)",
        "Below Average (3.6–4.0)"
      ),
      include.lowest = TRUE
    )
    
    # Count number of students per cluster
    df_clustered <- aggregate(matriculation_number ~ cluster, data = df, FUN = length)
    names(df_clustered)[2] <- "count"
    
    # Calculate percentages
    df_clustered$percent <- round(df_clustered$count / sum(df_clustered$count) * 100, 1)
    
    # Build combined slice label: "XX% (YY)"
    df_clustered$label <- paste0(df_clustered$percent, "% (", df_clustered$count, ")")
    
    # Pie chart
    ggplot(df_clustered, aes(x = "", y = count, fill = cluster)) +
      geom_bar(stat = "identity", width = 1, color = "black") +  
      geom_text(
        aes(label = label),
        position = position_stack(vjust = 0.5),
        size = 8,
        fontface = "bold"
      ) +
      coord_polar("y") +
      scale_fill_manual(
        values = c(
          "Very Good (≤1.5)" = "#3c8d40",
          "Good (1.6–2.5)"   = "#88c999",
          "Average (2.6–3.5)"= "#f3b173",
          "Below Average (3.6–4.0)"    = "#e16b6b"
        )
      ) +
      labs(
        title = "Overall Performance Overview",
        subtitle = paste("Total number of students:", total_students),
        fill  = "Grade Cluster"
      ) +
      theme_void() +
      theme(
        plot.title    = element_text(size = 20, face = "bold", hjust = 0.5, margin = margin(b = 5)),
        plot.subtitle = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 10)),
        legend.title  = element_text(size = 16),
        legend.text   = element_text(size = 14),
        legend.position = "right"
      )
  })
  
# ============================================================================
# switch between pie plot all students, or bar plot one student 
# ============================================================================  
  observe({
    if (input$student_toggle == "One Student") {
      shinyjs::show("bar_container")
      shinyjs::hide("pie_container")
    } else {
      shinyjs::hide("bar_container")
      shinyjs::show("pie_container")
    }
  })
  
  
# ============================================================================
# BOX PLOT – Distribution of all students' average grades
# ============================================================================
  output$boxplot_avg <- renderPlot({
    
    df <- all_student_averages
    
    # Overall statistics
    overall_mean   <- overall_average
    overall_median <- median(df$student_avg, na.rm = TRUE)
    overall_sd     <- sd(df$student_avg, na.rm = TRUE)
    
    p <- ggplot(df, aes(x = 1, y = student_avg)) +
      
      # Standard boxplot
      geom_boxplot(
        width = 0.5,
        fill = "lightblue",
        color = "black"
      ) +
      
      # Overall mean (blue line)
      annotate(
        "segment",
        x = 0.75, xend = 1.25,
        y = overall_mean, yend = overall_mean,
        color = "blue",
        linewidth = 1.2
      ) +
      
      # Mean label (left)
      annotate(
        "text",
        x = 0.725,
        y = overall_mean,
        label = paste0("Mean: ", round(overall_mean, 2)),
        hjust = 1,
        vjust = 0.5,
        color = "blue",
        size = 4,
        fontface = "bold"
      ) +
      
      # Median label (right)
      annotate(
        "text",
        x = 1.275,
        y = overall_median,
        label = paste0("Median: ", round(overall_median, 2)),
        hjust = 0,
        vjust = 0.5,
        color = "black",
        size = 4,
        fontface = "bold"
      ) +
      
      labs(
        y = "Average Grade",
        x = NULL,
        title = "Distribution of Average Grades\nAcross All Students",
        subtitle = paste0(
          "Median: ", round(overall_median, 2),
          "   |   SD: ", round(overall_sd, 2)
        )
      ) +
      
      scale_x_continuous(limits = c(0.4, 1.6)) +
      
      theme_minimal(base_size = 14) +
      theme(
        plot.title    = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 14, hjust = 0.5),
        
        axis.text.x   = element_blank(),
        axis.ticks.x  = element_blank(),
        axis.text.y   = element_text(face = "bold", size = 12, color = "black"),
        
        # ------------------------------------------------------------
        # Grid styling (same as bar plot / histogram)
        # ------------------------------------------------------------
        panel.grid.major.y = element_line(
          color = "grey70",
          linewidth = 0.8
        ),
        panel.grid.major.x = element_line(
          color = "grey85",
          linewidth = 0.6
        ),
        panel.grid.minor = element_blank()
      )
    
# ----------------------------------------------------
# Add student mean (red line) ONLY in One Student mode
# ----------------------------------------------------
    if (input$student_toggle == "One Student") {
      
      df_student <- student_grades_for_plot()
      
      if (!is.null(df_student) && nrow(df_student) > 0) {
        
        student_mean <- mean(df_student$grade, na.rm = TRUE)
        
        p <- p +
          annotate(
            "segment",
            x = 0.75, xend = 1.25,
            y = student_mean, yend = student_mean,
            color = "red",
            linewidth = 1.2
          ) +
          # Label on the right of the box
          annotate(
            "text",
            x = 1.265,
            y = student_mean,
            label = paste0("Student: ", round(student_mean, 2)),
            hjust = 0,
            vjust = 0.5,
            color = "red",
            size = 4,
            fontface = "bold"
          )
      }
    }
    
    # show plot
    p
    
  })
  
 
# ============================================================================
# Load Exam Data (incl. semester) for the dropdowns
# ============================================================================
  
exams <- dbGetQuery(
    con,
    "
  SELECT
    pnr,
    title,
    semester
  FROM exam
  "
  )

# ---- Semester dropdown choices (GLOBAL) ------------------------------------
semester_choices_exam <- c(
    "- all semester -",
    sort(unique(exams$semester))
  )

# ============================================================================
# Semester Filter (GLOBAL – used for All Exams & One Exam)
# ============================================================================
# This dropdown is ALWAYS visible and fixed in position.
  
  output$exam_semester_filter <- renderUI({
    selectInput(
      "exam_semester_select",
      label    = tags$label("Semester:", style = "margin-top: 25px;"),
      choices  = semester_choices_exam,
      selected = "- all semester -"
    )
  })

# ============================================================================
# Central Reactive: Exams filtered by semester
# ============================================================================
# Single source of truth for semester filtering
  
  filtered_exams <- reactive({
    
    df <- exams
    semester <- input$exam_semester_select
    
    if (!is.null(semester) && semester != "- all semester -") {
      df <- df[df$semester == semester, ]
    }
    
    df
  })
  
# ============================================================================
# Reactive: Dropdown choices (semester-aware)
# ============================================================================
  
  exam_title_choices_one <- reactive({
    c(
      "- not selected -",
      sort(unique(filtered_exams()$title))
    )
  })
  
  exam_pnr_choices_one <- reactive({
    c(
      "- not selected -",
      sort(unique(filtered_exams()$pnr))
    )
  })
  
# ============================================================================
# Dynamic Input Row (for "One Exam")
# ============================================================================
# NOTE:
# - NO semester dropdown here anymore
# - Semester is controlled ONLY by the global filter above
  
  output$one_exam_filters <- renderUI({
    
    req(input$exam_toggle == "One Exam")
    
    title_selected <- !is.null(input$exam_title_select) &&
      input$exam_title_select != "- not selected -"
    
    pnr_selected <- !is.null(input$exam_pnr_select) &&
      input$exam_pnr_select != "- not selected -"
    
    div(
      style = "display: flex; align-items: flex-start; gap: 20px; margin-top: 20px;",
      
# ---------------- Exam Title ----------------
      if (!pnr_selected) {
        selectInput(
          "exam_title_select",
          label = tags$label(
            "Exam Title:",
            style = "margin-top: 6px;"
          ),
          choices  = exam_title_choices_one(),
          selected = input$exam_title_select %||% "- not selected -"
        )
      } else {
        div(
          class = "static-text-container",
          style = "margin-top: 0px;",
          
          tags$label(
            "Exam Title:",
            style = "margin-top: 6px;"
          ),
          
          div(
            class = "static-text-input",
            style = "margin-top: 5px;",
            filtered_exams()[
              filtered_exams()$pnr == input$exam_pnr_select,
            ]$title
          )
        )
      },
      
# ---------------- Exam Number ----------------
      if (!title_selected) {
        selectInput(
          "exam_pnr_select",
          label = tags$label(
            "Exam Number:",
            style = "margin-top: 6px;"
          ),
          choices  = exam_pnr_choices_one(),
          selected = input$exam_pnr_select %||% "- not selected -"
        )
      } else {
        div(
          class = "static-text-container",
          style = "margin-top: 0px;",
          
          tags$label(
            "Exam Number:",
            style = "margin-top: 6px;"
          ),
          
          div(
            class = "static-text-input",
            style = "margin-top: 5px;",
            filtered_exams()[
              filtered_exams()$title == input$exam_title_select,
            ]$pnr
          )
        )
      },
      
# ---------------- Reset Button ----------------
      actionButton(
        "reset_exam_filters",
        "Reset Selection",
        class = "reset-btn",
        style = "margin-top:35px;"
      )
    )
  })
  
  
# ============================================================================
# Reset Logic (One Exam)
# ============================================================================
# Semester intentionally NOT reset
  
  observeEvent(input$reset_exam_filters, {
    updateSelectInput(session, "exam_title_select", selected = "- not selected -")
    updateSelectInput(session, "exam_pnr_select",   selected = "- not selected -")
  })
  
  
# ============================================================================
# Show / Hide Exam Reset Button
# ============================================================================
  
  observe({
    if (
      (!is.null(input$exam_title_select) &&
       input$exam_title_select != "- not selected -") ||
      (!is.null(input$exam_pnr_select) &&
       input$exam_pnr_select != "- not selected -")
    ) {
      shinyjs::show("reset_exam_filters")
    } else {
      shinyjs::hide("reset_exam_filters")
    }
  })
  

# ============================================================================  
# Load All Grades for All Exams 
# ============================================================================
# This query loads all grades for all exams and will be used for both the "All Exams" plot
# and the "One Exam" filtering later. We do it outside of any reactive to avoid repeated DB hits.
  all_grades <- dbGetQuery(con, "
  SELECT
    g.grade,
    g.matriculation_number,
    g.pnr,
    e.title          AS exam_title,
    e.semester       AS semester,
    e.degree_program AS degree_program
  FROM grade g
  JOIN exam e ON g.pnr = e.pnr
")
  
  # Ensure exam_title is a factor to preserve order in plots
  all_grades$exam_title <- factor(all_grades$exam_title, levels = unique(all_grades$exam_title))
  
 
# ============================================================================
# Reactive: active semester (shared by All Exams & One Exam)
# ============================================================================
active_exam_semester <- reactive({
    
    if (input$exam_toggle == "One Exam") {
      input$exam_semester_select_one
    } else {
      input$exam_semester_select
    }
    
})  

  
  
# ============================================================================
# Reactive: Filter grades by semester (ONLY for All Exams mode)
# ============================================================================
  filtered_grades <- reactive({
    
    req(all_grades)
    
    semester_selected <- active_exam_semester()
    
    if (is.null(semester_selected) || semester_selected == "- all semester -") {
      all_grades
    } else {
      all_grades[all_grades$semester == semester_selected, ]
    }
})
 
# ============================================================================
# Reactive: Average grade of the selected exam (PNR preferred, title fallback)
# ============================================================================
  selected_exam_avg <- reactive({
    
    req(input$exam_toggle == "One Exam")
    
    df <- filtered_grades()
    req(nrow(df) > 0)
    
# ------------------------------------------------------------
# Case 1: PNR selected (preferred, unique)
# ------------------------------------------------------------
    if (!is.null(input$exam_pnr_select) &&
        input$exam_pnr_select != "- not selected -") {
      
      df <- df[df$pnr == input$exam_pnr_select, ]
      
# ------------------------------------------------------------
# Case 2: Only exam title selected (fallback)
# ------------------------------------------------------------
    } else if (!is.null(input$exam_title_select) &&
               input$exam_title_select != "- not selected -") {
      
      df <- df[df$exam_title == input$exam_title_select, ]
      
    } else {
      return(NULL)
    }
    
    req(nrow(df) > 0)
    
    mean(df$grade, na.rm = TRUE)
})
  
# ============================================================================
# LEFT PLOT 2 – Reactive: All individual grades of the selected exam
# ============================================================================
  
selected_exam_grades <- reactive({
    
    # This reactive is only relevant in "One Exam" mode
    req(input$exam_toggle == "One Exam")
    
    # Start from the centrally filtered grade dataset
    df <- filtered_grades()
    req(nrow(df) > 0)
    
# ------------------------------------------------------------
# Case 1: Exam Number (PNR) selected
# ------------------------------------------------------------
# The PNR uniquely identifies an exam and is therefore preferred
    if (!is.null(input$exam_pnr_select) &&
        input$exam_pnr_select != "- not selected -") {
      
      df <- df[df$pnr == input$exam_pnr_select, ]
      
# ------------------------------------------------------------
# Case 2: Exam Title selected (fallback)
# ------------------------------------------------------------
# This case is only used if no PNR is selected.
# It assumes that the combination of semester + title is sufficient.
    } else if (!is.null(input$exam_title_select) &&
               input$exam_title_select != "- not selected -") {
      
      df <- df[df$exam_title == input$exam_title_select, ]
      
# ------------------------------------------------------------
# Case 3: No valid exam selection
# ------------------------------------------------------------
    } else {
      return(NULL)
    }
    
    # Ensure that at least one grade exists for the selected exam
    req(nrow(df) > 0)
    
    # Return all individual grades of the selected exam
    df
  })
  
  
# ============================================================================
# LEFT PLOT 1: Scatter Plot of All Grades per Exam (All Exams Mode)
# ============================================================================
  output$exam_plot1 <- renderPlot({
    
    req(input$exam_toggle == "All Exams")
    
    df <- filtered_grades()
    req(nrow(df) > 0)
    
# ------------------------------------------------------------
# Create unique exam label for Y-axis (PNR + exam title)
# ------------------------------------------------------------
    df$exam_label <- paste0(df$pnr, " – ", df$exam_title)
    df$exam_label <- factor(df$exam_label, levels = unique(df$exam_label))
    
# ------------------------------------------------------------
# Color definition for grade clusters
# ------------------------------------------------------------
    grade_colors <- c(
      "Very Good (≤1.5)" = "#3c8d40",
      "Good (1.6–2.5)"   = "#88c999",
      "Average (2.6–3.5)"= "#f3b173",
      "Below Average (3.6–4.0)"   = "#e16b6b"
    )
    
# ------------------------------------------------------------
# Assign grade clusters
# ------------------------------------------------------------
    df$cluster <- cut(
      df$grade,
      breaks = c(0, 1.5, 2.5, 3.5, 4.1),
      labels = c(
        "Very Good (≤1.5)",
        "Good (1.6–2.5)",
        "Average (2.6–3.5)",
        "Below Average (3.6–4.0)"
      ),
      include.lowest = TRUE
    )
    
# ------------------------------------------------------------
# Scatter plot
# ------------------------------------------------------------
    ggplot(df, aes(y = exam_label, x = grade, color = cluster)) +
      
      # Grade threshold reference lines
      geom_vline(
        xintercept = c(1.5, 2.5, 3.5),
        color = "black",
        linewidth = 1
      ) +
      
      # Individual student grades
      geom_jitter(height = 0, size = 3, alpha = 1) +
      
      # Manual color scale
      scale_color_manual(values = grade_colors) +
      
      # Labels
      labs(
        title = "All Student Grades per Exam",
        x = "Grade",
        y = "Exam",
        color = "Grade Cluster"
      ) +
      
      # Theme
      theme_minimal(base_size = 14) +
      theme(
        plot.title       = element_text(face = "bold", size = 18, hjust = 0.5),
        axis.title.x     = element_text(face = "bold", size = 16),
        axis.title.y     = element_text(face = "bold", size = 16),
        axis.text.x      = element_text(size = 14),
        axis.text.y      = element_text(size = 12),
        panel.grid.major = element_line(color = "grey70"),
        panel.grid.minor = element_line(color = "grey85"),
        legend.title     = element_text(face = "bold", size = 14),
        legend.text      = element_text(size = 12)
      )
  })
  
# ============================================================================
# Dynamic plotOutput height for exam_plot1
# ============================================================================
  output$exam_plot1_ui <- renderUI({
    
    req(input$exam_toggle == "All Exams")
    
    df <- filtered_grades()
    req(!is.null(df))
    req(nrow(df) > 0)
    
    # Use unique exam labels (PNR + title) for height calculation
    exam_labels <- paste0("PNR ", df$pnr, " – ", df$exam_title)
    n_exams <- length(unique(exam_labels))
    
    # Height grows with number of exams (enables scrolling)
    h <- max(400, n_exams * 35)
    
    plotOutput(
      "exam_plot1",
      height = paste0(h, "px"),
      width  = "100%"
    )
  })
  

  # ============================================================================
  # LEFT PLOT 2: for One Exam Mode
  # ============================================================================
  # Histogram of grade distribution for one selected exam
  output$exam_plot2 <- renderPlot({
    
    # Only relevant in One Exam mode
    req(input$exam_toggle == "One Exam")
    
    # Get all grades of the selected exam
    df <- selected_exam_grades()
    req(!is.null(df))
    req(nrow(df) > 0)
    
    # ------------------------------------------------------------
    # Define official grading scale (HS Aalen – 0.3 steps)
    # ------------------------------------------------------------
    grade_levels <- c(
      1.0, 1.3, 1.7,
      2.0, 2.3, 2.7,
      3.0, 3.3, 3.7,
      4.0,
      "> 4.0"
    )
    
    # ------------------------------------------------------------
    # Color definition (consistent with other plots)
    # ------------------------------------------------------------
    grade_colors <- c(
      "Very Good (≤1.5)" = "#3c8d40",
      "Good (1.6–2.5)"   = "#88c999",
      "Average (2.6–3.5)"= "#f3b173",
      "Below Average (3.6–6.0)"   = "#e16b6b"
    )
    
    # ------------------------------------------------------------
    # Collect all failing grades (> 4.0) into one category
    # ------------------------------------------------------------
    df$grade_plot <- ifelse(
      df$grade > 4.0,
      "> 4.0",
      as.character(df$grade)
    )
    
    # Convert grades to ordered factor
    df$grade_factor <- factor(
      df$grade_plot,
      levels = grade_levels,
      ordered = TRUE
    )
    
    # ------------------------------------------------------------
    # Count number of students per grade (keep empty grades)
    # ------------------------------------------------------------
    grade_counts <- as.data.frame(table(df$grade_factor))
    names(grade_counts) <- c("grade", "count")
    
    # ------------------------------------------------------------
    # Assign performance cluster per grade level (for coloring)
    # ------------------------------------------------------------
    grade_counts$grade_num <- suppressWarnings(
      as.numeric(as.character(grade_counts$grade))
    )
    
    grade_counts$grade_cluster <- cut(
      grade_counts$grade_num,
      breaks = c(0, 1.5, 2.5, 3.5, 6.0),
      labels = c(
        "Very Good (≤1.5)",
        "Good (1.6–2.5)",
        "Average (2.6–3.5)",
        "Below Average (3.6–6.0)"
      ),
      include.lowest = TRUE
    )
    
    # Assign failing grades (>4.0) explicitly to "Below Average"
    grade_counts$grade_cluster[
      is.na(grade_counts$grade_cluster)
    ] <- "Below Average (3.6–6.0)"
    
    grade_counts$grade_cluster <- factor(
      grade_counts$grade_cluster,
      levels = names(grade_colors)
    )
    
    # ------------------------------------------------------------
    # Exam average for reference line
    # ------------------------------------------------------------
    ex_avg <- selected_exam_avg()
    n_students <- nrow(df)
    exam_title <- unique(df$exam_title)
    
    mean_x <- as.numeric(
      factor(
        min(grade_levels[grade_levels >= ex_avg]),
        levels = grade_levels
      )
    )
    
    # ------------------------------------------------------------
    # Plot
    # ------------------------------------------------------------
    ggplot(grade_counts, aes(x = grade, y = count)) +
      
      geom_col(
        aes(fill = grade_cluster),
        color = "black",
        width = 0.7
      ) +
      
      scale_fill_manual(
        name   = "Grade Cluster",
        values = grade_colors,
        drop   = TRUE
      ) +
      
      # ------------------------------------------------------------
    # Show count labels near the bottom of each bar
    # ------------------------------------------------------------
    geom_text(
      aes(label = ifelse(count > 0, count, "")),
      y = 0.5,
      fontface = "bold",
      size = 5,
      color = "black",
      vjust = 0
    ) +
      
      # ------------------------------------------------------------
    # Mean reference line + fixed-position label
    # ------------------------------------------------------------
    geom_vline(
      xintercept = mean_x,
      color = "red",
      linewidth = 1.2
    ) +
      
      annotate(
        "text",
        x = mean_x,
        y = 0.25,
        label = paste0("Mean: ", round(ex_avg, 2)),
        color = "red",
        fontface = "bold",
        size = 4,
        hjust = -0.1
      ) +
      
      labs(
        title = paste0("Grade Distribution – ", exam_title),
        subtitle = paste0("Number of students: ", n_students),
        x = "Grade",
        y = "Number of Students"
      ) +
      
      scale_y_continuous(
        breaks = seq(0, max(grade_counts$count), by = 1),
        expand = expansion(mult = c(0, 0.15))
      ) +
      
      theme_minimal(base_size = 14) +
      theme(
        plot.title    = element_text(face = "bold", size = 18, hjust = 0.5),
        plot.subtitle = element_text(size = 14, hjust = 0.5),
        axis.title.x  = element_text(face = "bold", size = 14),
        axis.title.y  = element_text(face = "bold", size = 14),
        axis.text.x   = element_text(face = "bold", size = 12),
        axis.text.y   = element_text(size = 12),
        panel.grid.major.y = element_line(color = "grey70", linewidth = 0.8),
        panel.grid.major.x = element_line(color = "grey85", linewidth = 0.6),
        panel.grid.minor   = element_blank()
      )
  })
  
# ============================================================================
# SHOW / HIDE LEFT CONTAINERS BASED ON RADIO BUTTON
# ============================================================================
# When "All Exams" is selected, only left1 is visible.
# When "One Exam" is selected, left2 is visible 
  observe({
    if (input$exam_toggle == "All Exams") {
      shinyjs::show("exam_plot_container1")
      shinyjs::hide("exam_plot_container2")
    } else if (input$exam_toggle == "One Exam") {
      shinyjs::hide("exam_plot_container1")
      shinyjs::show("exam_plot_container2")
    }
  })
  
  
# ============================================================================
# Reactive: Average grade per exam (respects semester filter)
# ============================================================================
  exam_averages_filtered <- reactive({
    
    df <- filtered_grades()
    req(nrow(df) > 0)
    
    aggregate(
      grade ~ exam_title,
      data = df,
      FUN = mean
    )
  })
  
# ============================================================================
# Reactive: Statistics of exam averages (semester-aware)
# ============================================================================
  exam_stats <- reactive({
    
    df <- exam_averages_filtered()
    req(nrow(df) > 1)   # boxplot needs more than one value
    
    list(
      mean   = mean(df$grade, na.rm = TRUE),
      median = median(df$grade, na.rm = TRUE),
      sd     = sd(df$grade, na.rm = TRUE)
    )
  })

# ============================================================================
# BOX PLOT – Distribution of Exam Average Grades (Semester-aware)
# ============================================================================
  output$exam_boxplot_avg <- renderPlot({
    
    df    <- exam_averages_filtered()
    stats <- exam_stats()
    
    p <- ggplot(df, aes(x = 1, y = grade)) +
      
# ----------------------------------------------------
# Boxplot of exam averages
# ----------------------------------------------------
    geom_boxplot(
      width = 0.5,
      fill  = "lightblue",
      color = "black"
    ) +
      
# ----------------------------------------------------
# Mean line (blue)
# ----------------------------------------------------
    annotate(
      "segment",
      x = 0.75, xend = 1.25,
      y = stats$mean, yend = stats$mean,
      color = "blue",
      linewidth = 1.2
    ) +
      
      # Mean label (left)
      annotate(
        "text",
        x = 0.72,
        y = stats$mean,
        label = paste0("Mean: ", round(stats$mean, 2)),
        hjust = 1,
        color = "blue",
        fontface = "bold",
        size = 4
      ) +
      
      # Median label (right)
      annotate(
        "text",
        x = 1.28,
        y = stats$median,
        label = paste0("Median: ", round(stats$median, 2)),
        hjust = 0,
        fontface = "bold",
        size = 4
      ) +
      
      labs(
        title = "Distribution of Exam Average Grades",
        subtitle = paste0(
          "Median: ", round(stats$median, 2),
          "   |   SD: ", round(stats$sd, 2)
        ),
        y = "Average Grade",
        x = NULL
      ) +
      
      scale_x_continuous(limits = c(0.4, 1.6)) +
      
      theme_minimal(base_size = 14) +
      theme(
        plot.title    = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 14, hjust = 0.5),
        
        axis.text.x   = element_blank(),
        axis.ticks.x  = element_blank(),
        axis.text.y   = element_text(face = "bold", size = 12, color = "black"),
        
        # ------------------------------------------------------------
        # Grid styling (same as bar plot / histogram)
        # ------------------------------------------------------------
        panel.grid.major.y = element_line(
          color = "grey70",
          linewidth = 0.8
        ),
        panel.grid.major.x = element_line(
          color = "grey85",
          linewidth = 0.6
        ),
        panel.grid.minor = element_blank()
      )
    
# ----------------------------------------------------
# One Exam mode → add selected exam average (red line)
# ----------------------------------------------------
    if (input$exam_toggle == "One Exam") {
      
      ex_avg <- selected_exam_avg()
      
      if (!is.null(ex_avg) && is.numeric(ex_avg)) {
        
        p <- p +
          annotate(
            "segment",
            x = 0.75, xend = 1.25,
            y = ex_avg, yend = ex_avg,
            color = "red",
            linewidth = 1.2
          ) +
          annotate(
            "text",
            x = 1.265,
            y = ex_avg,
            label = paste0("Exam: ", round(ex_avg, 2)),
            hjust = 0,
            vjust = 0.5,
            color = "red",
            fontface = "bold",
            size = 4
          )
      }
    }
        p
  })
  

# ============================================================================
# Exam GPA Value Output (Upper Card)
# ============================================================================
# Displays the main numeric value in the Exam GPA card.

output$exam_gpa_value <- renderText({
    
    # ---------------- All Exams Mode ----------------
    # Display overall or semester-specific exam average with standard deviation
    if (input$exam_toggle == "All Exams") {
      
      # Retrieve centralized exam statistics
      stats <- exam_stats()
      req(stats)
      
      # Format: Mean ± SD
      return(
        paste0(
          round(stats$mean, 2),
          " ± ",
          round(stats$sd, 2)
        )
      )
    }
    
    # ---------------- One Exam Mode ----------------
    req(input$exam_toggle == "One Exam")
    
    ex_avg <- selected_exam_avg()
    
    # not selected
    if (is.null(ex_avg) || !is.numeric(ex_avg)) {
      return("-")
    }
    
    # selected
    round(ex_avg, 2)
  })
  

# ============================================================================
# Dynamic title for the Exam GPA card
# ============================================================================
# The title adapts based on:
# - Exam toggle (All Exams vs. One Exam)
# - Semester filter selection
 
output$exam_gpa_title <- renderUI({
    
    title <- if (input$exam_toggle == "All Exams") {
      
# ---------------- All Exams Mode ----------------
      # Distinguish between overall and semester-specific aggregation
      if (is.null(input$exam_semester_select) ||
          input$exam_semester_select == "- all semester -") {
        
        # Overall average across all exams and semesters
        HTML("Overall<br>Exam Average")
        
      } else {
        
        # Semester-specific average across all exams
        HTML("Semester<br>Exam Average")
      }
      
    } else {
      
# ---------------- One Exam Mode ----------------
# Displays the average grade of the selected exam
      "Exam Average"
    }
    
    # Render the title with consistent styling
    h3(
      title,
      style = "
      margin: 0;
      margin-bottom: 10px;
      font-size: 20px;
      font-weight: bold;
      text-align: center;
    "
    )
  })

  
# ============================================================================
# Load Degree Program Data (incl. semester)
# ============================================================================
  degrees <- dbGetQuery(
    con,
    "
  SELECT DISTINCT
    e.degree_program,
    e.semester
  FROM exam e
  ORDER BY e.degree_program, e.semester
  "
  )
  
# ---- Sort variants ----------------------------------------------------------
  degrees_sorted_prog <- degrees[order(degrees$degree_program), ]
  degrees_sorted_sem  <- degrees[order(degrees$semester), ]
  
# ---- Dropdown choices -------------------------------------------------------
  degree_choices   <- c("- not selected -", unique(degrees_sorted_prog$degree_program))
  semester_choices <- c("- all semester -", unique(degrees_sorted_sem$semester))
  
  
# ============================================================================
# Semester Filter (Degree – shared for All Programs & One Program)
# ============================================================================
  output$degree_semester_filter <- renderUI({
    
    div(
      style = "display: flex; align-items: flex-start; gap: 20px; margin-top: 20px;",
      selectInput(
        "degree_semester_select",
        label    = tags$label("Semester:", style = "margin-top: 6px;"),
        choices  = semester_choices,
        selected = "- all semester -"
      )
    )
  })
  
  
# ============================================================================
# Reactive: Degree programs filtered by semester
# ============================================================================
  filtered_degrees_one <- reactive({
    
    df <- degrees
    semester <- input$degree_semester_select
    
    if (!is.null(semester) && semester != "- all semester -") {
      df <- df[df$semester == semester, ]
    }
    
    df
  })
  
  
# ============================================================================
# Reactive: Degree program dropdown choices (semester-aware)
# ============================================================================
  degree_program_choices_one <- reactive({
    c(
      "- not selected -",
      sort(unique(filtered_degrees_one()$degree_program))
    )
  })
  
  
# ============================================================================
# Dynamic Input Row (for "One Program")
# ============================================================================
  output$one_degree_filters <- renderUI({
    
    req(input$degree_toggle == "One Program")
    
    div(
      style = "display: flex; align-items: flex-start; gap: 20px; margin-top: 20px;",
      
      # ---------------- Degree Program ---------------------------------------
      selectInput(
        "degree_program_select",
        label    = tags$label("Degree Program:", style = "margin-top: 6px;"),
        choices  = degree_program_choices_one(),
        selected = input$degree_program_select %||% "- not selected -"
      ),
      
      # ---------------- Reset Button -----------------------------------------
      actionButton(
        "reset_degree_filters",
        "Reset Selection",
        class = "reset-btn",
        style = "margin-top:35px; box-shadow: 0px 2px 6px rgba(0,0,0,0.2);"
      )
    )
  })
  
  
# ============================================================================
# Reset Degree Filters
# ============================================================================
  observeEvent(input$reset_degree_filters, {
    updateSelectInput(session, "degree_program_select", selected = "- not selected -")
    updateSelectInput(session, "degree_semester_select", selected = "- all semester -")
  })
  
  
# ============================================================================
# Show / Hide Degree Reset Button
# ============================================================================
  observe({
    if (!is.null(input$degree_program_select) &&
        input$degree_program_select != "- not selected -") {
      shinyjs::show("reset_degree_filters")
    } else {
      shinyjs::hide("reset_degree_filters")
    }
  })
 
  
# ============================================================================
# Reactive: Exam averages per Degree Program (semester-aware)
# ----------------------------------------------------------------------------
degree_exam_averages <- reactive({
    
    # Ensure the central grade dataset is available
    req(all_grades)
    
    # Start from the complete dataset
    df <- all_grades
    
# ------------------------------------------------------------
# Apply semester filter (Degree tab)
# ------------------------------------------------------------
# If a specific semester is selected, only keep exams
# that were held in that semester.
    if (!is.null(input$degree_semester_select) &&
        input$degree_semester_select != "- all semester -") {
      
      df <- df[df$semester == input$degree_semester_select, ]
    }
    
    # Ensure that data is still available after filtering
    req(nrow(df) > 0)
    
# ------------------------------------------------------------
# Aggregate grades
# ------------------------------------------------------------
# One row = one exam
# grade   = average grade of that exam
    aggregate(
      grade ~ degree_program + pnr + exam_title,
      data = df,
      FUN  = mean
    )
})
  
# ============================================================================
# LEFT PLOT 1 – Scatter Plot
# ----------------------------------------------------------------------------
  output$degree_plot1 <- renderPlot({
    
# Plot is only relevant in "All Programs" mode
    req(input$degree_toggle == "All Programs")
    
# Get aggregated exam averages
    df <- degree_exam_averages()
    req(nrow(df) > 0)
    
# ------------------------------------------------------------
# Assign grade clusters (consistent terminology)
# ------------------------------------------------------------
    df$cluster <- cut(
      df$grade,
      breaks = c(0, 1.5, 2.5, 3.5, 6.0),
      labels = c(
        "Very Good (≤1.5)",
        "Good (1.6–2.5)",
        "Average (2.6–3.5)",
        "Below Average (3.6–6.0)"
      ),
      include.lowest = TRUE
    )
    
# Consistent color mapping used across the dashboard
    grade_colors <- c(
      "Very Good (≤1.5)"        = "#3c8d40",
      "Good (1.6–2.5)"          = "#88c999",
      "Average (2.6–3.5)"       = "#f3b173",
      "Below Average (3.6–6.0)" = "#e16b6b"
    )
    
# ------------------------------------------------------------
# Scatter plot
# ------------------------------------------------------------
    ggplot(df, aes(
      y = degree_program,
      x = grade,
      color = cluster
    )) +
      
# Reference lines for grading thresholds
      geom_vline(
        xintercept = c(1.5, 2.5, 3.5),
        color = "black",
        linewidth = 1
      ) +
      
# One jittered point per exam average
      geom_jitter(
        height = 0.15,
        size   = 3,
        alpha  = 1
      ) +
      
# Apply consistent color palette
      scale_color_manual(values = grade_colors) +
      
# Axis labels and title
      labs(
        title = "Exam Average Grades per Degree Program",
        subtitle = if (
          is.null(input$degree_semester_select) ||
          input$degree_semester_select == "- all semester -"
        ) {
          "All semesters"
        } else {
          paste("Semester:", input$degree_semester_select)
        },
        x = "Average Grade per Exam",
        y = "Degree Program",
        color = "Grade Cluster"
      ) +
      
# Theme consistent with Exam scatter plot
      theme_minimal(base_size = 14) +
      theme(
        plot.title       = element_text(face = "bold", size = 18, hjust = 0.5),
        plot.subtitle    = element_text(size = 14, hjust = 0.5),
        axis.title.x     = element_text(face = "bold", size = 16),
        axis.title.y     = element_text(face = "bold", size = 16),
        axis.text.x      = element_text(size = 14),
        axis.text.y      = element_text(size = 12),
        panel.grid.major = element_line(color = "grey70"),
        panel.grid.minor = element_line(color = "grey85"),
        legend.title     = element_text(face = "bold", size = 14),
        legend.text      = element_text(size = 12)
      )
  })
  
  
  

# ============================================================================
# Dynamic plotOutput height for Degree scatter plot
# ============================================================================
  output$degree_plot1_ui <- renderUI({
    
    req(input$degree_toggle == "All Programs")
    
    df <- degree_exam_averages()
    req(nrow(df) > 0)
    
    # Height scales with number of degree programs
    n_degrees <- length(unique(df$degree_program))
    height_px <- max(400, n_degrees * 35)
    
    plotOutput(
      "degree_plot1",
      height = paste0(height_px, "px"),
      width  = "100%"
    )
})
  
# ============================================================================
# Reactive: All individual grades for selected Degree Program
# ============================================================================
  degree_program_grades <- reactive({
    
    req(input$degree_toggle == "One Program")
    req(input$degree_program_select)
    req(input$degree_program_select != "- not selected -")
    
    df <- all_grades
    
    # Semester filter (degree tab)
    if (!is.null(input$degree_semester_select) &&
        input$degree_semester_select != "- all semester -") {
      df <- df[df$semester == input$degree_semester_select, ]
    }
    
    # Degree program filter
    df <- df[df$degree_program == input$degree_program_select, ]
    
    req(nrow(df) > 0)
    
    df
  })
  
# ============================================================================
# LEFT PLOT 2 – Grade Distribution for One Degree Program
# ============================================================================
  output$degree_plot2 <- renderPlot({
    
    req(input$degree_toggle == "One Program")
    
    df <- degree_program_grades()
    req(nrow(df) > 0)
    
# ------------------------------------------------------------
# Official grading scale (HS Aalen – 0.3 steps)
# ------------------------------------------------------------
    grade_levels <- c(
      1.0, 1.3, 1.7,
      2.0, 2.3, 2.7,
      3.0, 3.3, 3.7,
      4.0,
      "> 4.0"
    )
    
# ------------------------------------------------------------
# Color definition (global dashboard standard)
# ------------------------------------------------------------
    grade_colors <- c(
      "Very Good (≤1.5)"        = "#3c8d40",
      "Good (1.6–2.5)"          = "#88c999",
      "Average (2.6–3.5)"       = "#f3b173",
      "Below Average (3.6–6.0)" = "#e16b6b"
    )
    
# ------------------------------------------------------------
# Collapse failing grades (>4.0)
# ------------------------------------------------------------
    df$grade_plot <- ifelse(df$grade > 4.0, "> 4.0", as.character(df$grade))
    
    df$grade_factor <- factor(
      df$grade_plot,
      levels  = grade_levels,
      ordered = TRUE
    )
    
# ------------------------------------------------------------
# Count students per grade (keep empty bins)
# ------------------------------------------------------------
    grade_counts <- as.data.frame(table(df$grade_factor))
    names(grade_counts) <- c("grade", "count")
    
# ------------------------------------------------------------
# Assign grade clusters
# ------------------------------------------------------------
    grade_counts$grade_num <- suppressWarnings(
      as.numeric(as.character(grade_counts$grade))
    )
    
    grade_counts$grade_cluster <- cut(
      grade_counts$grade_num,
      breaks = c(0, 1.5, 2.5, 3.5, 6.0),
      labels = names(grade_colors),
      include.lowest = TRUE
    )
    
    grade_counts$grade_cluster[
      is.na(grade_counts$grade_cluster)
    ] <- "Below Average (3.6–6.0)"
    
# ------------------------------------------------------------
# Degree program average (mean of individual grades)
# ------------------------------------------------------------
    program_mean <- mean(df$grade, na.rm = TRUE)
    n_students   <- nrow(df)
    
    mean_x <- as.numeric(
      factor(
        min(grade_levels[grade_levels >= program_mean]),
        levels = grade_levels
      )
    )
    
# ------------------------------------------------------------
# Plot
# ------------------------------------------------------------
    ggplot(grade_counts, aes(x = grade, y = count)) +
      
      geom_col(
        aes(fill = grade_cluster),
        color = "black",
        width = 0.7
      ) +
      
      scale_fill_manual(
        name   = "Grade Cluster",
        values = grade_colors
      ) +
      
      geom_text(
        aes(label = ifelse(count > 0, count, "")),
        y = 0.5,
        fontface = "bold",
        size = 5,
        vjust = 0
      ) +
      
      geom_vline(
        xintercept = mean_x,
        color = "blue",
        linewidth = 1.2
      ) +
      
      annotate(
        "text",
        x = mean_x,
        y = 0.25,
        label = paste0("Mean: ", round(program_mean, 2)),
        color = "blue",
        fontface = "bold",
        size = 4,
        hjust = -0.1
      ) +
      
      labs(
        title = paste0(
          "Grade Distribution – ",
          input$degree_program_select
        ),
        subtitle = paste0(
          if (
            !is.null(input$degree_semester_select) &&
            input$degree_semester_select != "- all semester -"
          ) paste0("Semester: ", input$degree_semester_select," | ") else "",
          "Number of grades: ", n_students
        ),
        x = "Grade",
        y = "Number of Students"
      ) +
      
      scale_y_continuous(
        breaks = seq(0, max(grade_counts$count), by = 1),
        expand = expansion(mult = c(0, 0.15))
      ) +
      
      theme_minimal(base_size = 14) +
      theme(
        plot.title    = element_text(face = "bold", size = 18, hjust = 0.5),
        plot.subtitle = element_text(size = 14, hjust = 0.5),
        axis.title.x  = element_text(face = "bold", size = 14),
        axis.title.y  = element_text(face = "bold", size = 14),
        axis.text.x   = element_text(face = "bold", size = 12),
        axis.text.y   = element_text(size = 12),
        panel.grid.major.y = element_line(color = "grey70", linewidth = 0.8),
        panel.grid.major.x = element_line(color = "grey85", linewidth = 0.6),
        panel.grid.minor   = element_blank()
      )
})
  

# ============================================================================
# DEGREE BOXPLOT – Distribution of Exam Average Grades
# ----------------------------------------------------------------------------
# Shows the distribution of exam averages across all degree programs.
# - Semester-aware via degree_exam_averages()
# - In "One Program" mode, a red reference line is added
# ============================================================================
  output$degree_boxplot_all <- renderPlot({
    
# ------------------------------------------------------------
# Base data: exam averages per degree program (semester-aware)
# ------------------------------------------------------------
    df <- degree_exam_averages()
    req(nrow(df) > 1)
    
# ------------------------------------------------------------
# Overall statistics
# ------------------------------------------------------------
    overall_mean   <- mean(df$grade, na.rm = TRUE)
    overall_median <- median(df$grade, na.rm = TRUE)
    overall_sd     <- sd(df$grade, na.rm = TRUE)
    
# ------------------------------------------------------------
# Boxplot
# ------------------------------------------------------------
    p <- ggplot(df, aes(x = 1, y = grade)) +
      
      geom_boxplot(
        width = 0.5,
        fill  = "lightblue",
        color = "black"
      ) +
      
      annotate(
        "segment",
        x = 0.75, xend = 1.25,
        y = overall_mean, yend = overall_mean,
        color = "blue",
        linewidth = 1.2
      ) +
      
      annotate(
        "text",
        x = 0.72,
        y = overall_mean,
        label = paste0("Mean: ", round(overall_mean, 2)),
        hjust = 1,
        color = "blue",
        size = 4,
        fontface = "bold"
      ) +
      
      annotate(
        "text",
        x = 1.28,
        y = overall_median,
        label = paste0("Median: ", round(overall_median, 2)),
        hjust = 0,
        size = 4,
        fontface = "bold"
      ) +
      
      labs(
        title = "Distribution of Exam Average Grades\nAcross Degree Programs",
        subtitle = paste0(
          "Median: ", round(overall_median, 2),
          " | SD: ", round(overall_sd, 2)
        ),
        y = "Average Grade",
        x = NULL
      ) +
      
      scale_x_continuous(limits = c(0.4, 1.6)) +
      
      theme_minimal(base_size = 14) +
      theme(
        plot.title    = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 14, hjust = 0.5),
        axis.text.x   = element_blank(),
        axis.ticks.x  = element_blank(),
        axis.text.y   = element_text(face = "bold", size = 12, color = "black"),
        panel.grid.major.y = element_line(color = "grey70", linewidth = 0.8),
        panel.grid.major.x = element_line(color = "grey85", linewidth = 0.6),
        panel.grid.minor   = element_blank()
      )
    
# ------------------------------------------------------------
# return plot
# ------------------------------------------------------------
    p
})
  
  
# ============================================================================
# DEGREE BOXPLOT – One Program
# ----------------------------------------------------------------------------
# Distribution of ALL individual grades for the selected degree program
# - Semester-aware
# - Same layout as "All Programs" boxplot
# ============================================================================
  output$degree_boxplot_one <- renderPlot({
    
    req(input$degree_toggle == "One Program")
    req(input$degree_program_select)
    req(input$degree_program_select != "- not selected -")
    
# ------------------------------------------------------------
# Base data: all individual grades of the selected program
# ------------------------------------------------------------
    df <- degree_program_grades()
    req(nrow(df) > 1)   # Boxplot needs more than one value
    
# ------------------------------------------------------------
# Statistics
# ------------------------------------------------------------
    program_mean   <- mean(df$grade, na.rm = TRUE)
    program_median <- median(df$grade, na.rm = TRUE)
    program_sd     <- sd(df$grade, na.rm = TRUE)
    
# ------------------------------------------------------------
# Boxplot (same styling as All Programs)
# ------------------------------------------------------------
    ggplot(df, aes(x = 1, y = grade)) +
      
      geom_boxplot(
        width = 0.5,
        fill  = "lightblue",
        color = "black"
      ) +
      
# ------------------------------------------------------------
# Mean reference line (blue)
# ------------------------------------------------------------
    annotate(
      "segment",
      x = 0.75, xend = 1.25,
      y = program_mean, yend = program_mean,
      color = "blue",
      linewidth = 1.2
    ) +
      
# Mean label (left)
      annotate(
        "text",
        x = 0.72,
        y = program_mean,
        label = paste0("Mean: ", round(program_mean, 2)),
        hjust = 1,
        vjust = 0.5,
        color = "blue",
        size = 4,
        fontface = "bold"
      ) +
      
# Median label (right)
      annotate(
        "text",
        x = 1.28,
        y = program_median,
        label = paste0("Median: ", round(program_median, 2)),
        hjust = 0,
        vjust = 0.5,
        size = 4,
        fontface = "bold"
      ) +
      
      labs(
        title = if (
          is.null(input$degree_semester_select) ||
          input$degree_semester_select == "- all semester -"
        ) {
          "Distribution of Grades – All Semesters"
        } else {
          paste0(
            "Distribution of Grades – Semester ",
            input$degree_semester_select
          )
        },
        subtitle = paste0(
          "Median: ", round(program_median, 2),
          " | SD: ", round(program_sd, 2)
        ),
        y = "Grade",
        x = NULL
      ) +
      
      scale_x_continuous(limits = c(0.4, 1.6)) +
      
      theme_minimal(base_size = 14) +
      theme(
        plot.title    = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 14, hjust = 0.5),
        
        axis.text.x   = element_blank(),
        axis.ticks.x  = element_blank(),
        axis.text.y   = element_text(face = "bold", size = 12, color = "black"),
        
        panel.grid.major.y = element_line(
          color = "grey70",
          linewidth = 0.8
        ),
        panel.grid.major.x = element_line(
          color = "grey85",
          linewidth = 0.6
        ),
        panel.grid.minor = element_blank()
      )
})
  


# ============================================================================
# SHOW / HIDE LEFT CONTAINERS – DEGREE TAB
# ----------------------------------------------------------------------------
# When "All Programs" is selected:
#   - Show left container 1 (overview scatter plot)
#   - Hide left container 2 (detail view)
#
# When "One Program" is selected:
#   - Hide left container 1
#   - Show left container 2
# ============================================================================
  observe({
    
    req(input$degree_toggle)
    
    if (input$degree_toggle == "All Programs") {
      
      shinyjs::show("degree_plot_container1")
      shinyjs::hide("degree_plot_container2")
      
    } else if (input$degree_toggle == "One Program") {
      
      shinyjs::hide("degree_plot_container1")
      shinyjs::show("degree_plot_container2")
    }
  })  
    
# ============================================================================
# SHOW / HIDE DEGREE BOXPLOTS (RIGHT LOWER CARD)
# ============================================================================
  observe({
    
    req(input$degree_toggle)
    
    if (input$degree_toggle == "All Programs") {
      
      shinyjs::show("degree_boxplot_all_container")
      shinyjs::hide("degree_boxplot_one_container")
      
    } else if (input$degree_toggle == "One Program") {
      
      shinyjs::hide("degree_boxplot_all_container")
      shinyjs::show("degree_boxplot_one_container")
    }
  })
  
  
# ============================================================================
# Reactive: Statistics of degree exam averages (semester-aware)
# ============================================================================
  degree_stats <- reactive({
    
    df <- degree_exam_averages()
    req(nrow(df) > 1)
    
    list(
      mean = mean(df$grade, na.rm = TRUE),
      sd   = sd(df$grade, na.rm = TRUE)
    )
})  

# ============================================================================
# Degree KPI Value Output (Upper Card)
# ============================================================================
  output$degree_card1_value <- renderText({
    
# ---------------- All Programs ----------------
    if (input$degree_toggle == "All Programs") {
      
      stats <- degree_stats()
      req(stats)
      
      return(
        paste0(
          round(stats$mean, 2),
          " ± ",
          round(stats$sd, 2)
        )
      )
    }
    
    # ---------------- One Program ----------------
    req(input$degree_toggle == "One Program")
    req(input$degree_program_select)
    req(input$degree_program_select != "- not selected -")
    
    df <- degree_program_grades()
    req(nrow(df) > 1)
    
    program_mean <- mean(df$grade, na.rm = TRUE)
    program_sd   <- sd(df$grade, na.rm = TRUE)
    
    paste0(
      round(program_mean, 2),
      " ± ",
      round(program_sd, 2)
    )
})
  
  

# ============================================================================
# Dynamic title for Degree KPI card
# ============================================================================
  output$degree_card1_title <- renderUI({
    
    title <- if (input$degree_toggle == "All Programs") {
      
# Distinguish between overall and semester-specific aggregation
      if (is.null(input$degree_semester_select) ||
          input$degree_semester_select == "- all semester -") {
        
        HTML("Overall<br>Degree Program Average Grade")
        
      } else {
        
        HTML("Semester<br>Degree Program Average Grade")
      }
      
    } else {
      
# One Program mode
      HTML("Program<br>Average Grade")
    }
    
    h3(
      title,
      style = "
      margin: 0;
      margin-bottom: 10px;
      font-size: 20px;
      font-weight: bold;
      text-align: center;
    "
    )
})
  
  
# ============================================================================
# Disconnect when session ends
# ============================================================================
   session$onSessionEnded(function() {
    dbDisconnect(con)
  })
  
}
  