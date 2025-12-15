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
      "Average Grade"
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
      labs(x = "Grade", y = "Exam", title = "Student Grades Overview") +
      theme_minimal(base_size = 14) +
      theme(
        plot.background  = element_rect(fill = "white", color = NA, linewidth = 0),
        panel.background = element_rect(fill = "white", color = "grey90", linewidth = 1),
        panel.grid.major = element_line(color = "grey90"),
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
        "Poor (3.6–4.0)"
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
          "Poor (3.6–4.0)"    = "#e16b6b"
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
        axis.text.y   = element_text(face = "bold", size = 12, color = "black")
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
  
  # ---- Sort variants ---------------------------------------------------------
  exams_sorted_pnr   <- exams[order(exams$pnr), ]
  exams_sorted_title <- exams[order(exams$title), ]
  exams_sorted_sem   <- exams[order(exams$semester), ]
  
  # ---- Dropdown choices ------------------------------------------------------
  title_choices    <- c("- not selected -", exams_sorted_title$title)
  pnr_choices      <- c("- not selected -", exams_sorted_pnr$pnr)
  semester_choices <- c("- all semester -", unique(exams_sorted_sem$semester))
  
  
# ============================================================================
# Semester Filter (All Exams)
# ============================================================================
output$exam_semester_filter <- renderUI({
    req(input$exam_toggle == "All Exams")
    
    div(
      style = "display: flex; align-items: flex-start; gap: 20px; margin-top: 20px;",
      selectInput(
        "exam_semester_select",
        label    = tags$label("Semester:", style = "margin-top: 6px;"),
        choices  = semester_choices,
        selected = "- all semester -"
      )
    )
  })

# ============================================================================
# Dynamic Input Row (for "One Exam")
# Semester pre-filter logic included
# ============================================================================
  
# ---- Reactive: Exams filtered by semester ----------------------------------
filtered_exams_one <- reactive({
    df <- exams
    semester <- input$exam_semester_select_one
    
    if (!is.null(semester) && semester != "- all semester -") {
      df <- df[df$semester == semester, ]
    }
    
    df
  })
  
  # ---- Reactive: Dropdown choices --------------------------------------------
  exam_title_choices_one <- reactive({
    c(
      "- not selected -",
      sort(unique(filtered_exams_one()$title))
    )
  })
  
  exam_pnr_choices_one <- reactive({
    c(
      "- not selected -",
      sort(unique(filtered_exams_one()$pnr))
    )
  })
  
  
  # ---- UI --------------------------------------------------------------------
  output$one_exam_filters <- renderUI({
    req(input$exam_toggle == "One Exam")
    
    title_selected <- !is.null(input$exam_title_select) &&
      input$exam_title_select != "- not selected -"
    
    pnr_selected <- !is.null(input$exam_pnr_select) &&
      input$exam_pnr_select != "- not selected -"
    
    div(
      style = "display: flex; align-items: flex-start; gap: 20px; margin-top: 20px;",
      
      # ---------------- Semester ----------------------------------------------
      selectInput(
        "exam_semester_select_one",
        label    = tags$label("Semester:", style = "margin-top: 6px;"),
        choices  = semester_choices,
        selected = input$exam_semester_select_one %||% "- all semester -"
      ),
      
      # ---------------- Exam Title --------------------------------------------
      if (!pnr_selected) {
        selectInput(
          "exam_title_select",
          label    = tags$label("Exam Title:", style = "margin-top: 6px;"),
          choices  = exam_title_choices_one(),
          selected = input$exam_title_select %||% "- not selected -"
        )
      } else {
        div(
          class = "static-text-container",
          style = "margin-top: 0px;",
          tags$label("Exam Title:", style = "margin-top: 6px;"),
          div(
            class = "static-text-input",
            style = "margin-top: 5px; box-shadow: 0px 2px 6px rgba(0,0,0,0.2);",
            {
              row <- filtered_exams_one()[
                filtered_exams_one()$pnr == input$exam_pnr_select,
              ]
              row$title
            }
          )
        )
      },
      
      # ---------------- Exam Number -------------------------------------------
      if (!title_selected) {
        selectInput(
          "exam_pnr_select",
          label    = tags$label("Exam Number:", style = "margin-top: 6px;"),
          choices  = exam_pnr_choices_one(),
          selected = input$exam_pnr_select %||% "- not selected -"
        )
      } else {
        div(
          class = "static-text-container",
          style = "margin-top: 0px;",
          tags$label("Exam Number:", style = "margin-top: 6px;"),
          div(
            class = "static-text-input",
            style = "margin-top: 5px; box-shadow: 0px 2px 6px rgba(0,0,0,0.2);",
            {
              row <- filtered_exams_one()[
                filtered_exams_one()$title == input$exam_title_select,
              ]
              row$pnr
            }
          )
        )
      },
      
      # ---------------- Reset Button ------------------------------------------
      actionButton(
        "reset_exam_filters",
        "Reset Selection",
        class = "reset-btn",
        style = "margin-top:35px; box-shadow: 0px 2px 6px rgba(0,0,0,0.2);"
      )
    )
  })
  
  
  # ---- Reset logic ------------------------------------------------------------
  observeEvent(input$reset_exam_filters, {
    updateSelectInput(session, "exam_title_select", selected = "- not selected -")
    updateSelectInput(session, "exam_pnr_select",   selected = "- not selected -")
    updateSelectInput(session, "exam_semester_select_one",
                      selected = "- all semester -")
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
  
  
# ---------------- Load All Grades for All Exams ----------------
# This query loads all grades for all exams and will be used for both the "All Exams" plot
# and the "One Exam" filtering later. We do it outside of any reactive to avoid repeated DB hits.
  all_grades <- dbGetQuery(con, "
  SELECT
    g.grade,
    g.matriculation_number,
    g.pnr,
    e.title    AS exam_title,
    e.semester AS semester
  FROM grade g
  JOIN exam e ON g.pnr = e.pnr
")
  
  # Ensure exam_title is a factor to preserve order in plots
  all_grades$exam_title <- factor(all_grades$exam_title, levels = unique(all_grades$exam_title))
  
  
# ============================================================================
# Reactive: Filter grades by semester (ONLY for All Exams mode)
# ============================================================================
  filtered_grades <- reactive({
    
    req(all_grades)
    req(input$exam_toggle == "All Exams")
    
    semester_selected <- input$exam_semester_select
    
    if (is.null(semester_selected) || semester_selected == "- all semester -") {
      all_grades
    } else {
      all_grades[all_grades$semester == semester_selected, ]
    }
  })
  
  
# ============================================================================
# LEFT PLOT 1: Scatter Plot of All Grades per Exam (All Exams Mode)
# ============================================================================
  output$exam_plot1 <- renderPlot({
    
    req(input$exam_toggle == "All Exams")
    
    df <- filtered_grades()
    req(nrow(df) > 0)
    
    grade_colors <- c(
      "Very Good (≤1.5)" = "#3c8d40",
      "Good (1.6–2.5)"   = "#88c999",
      "Average (2.6–3.5)"= "#f3b173",
      "Poor (3.6–4.0)"   = "#e16b6b"
    )
    
    # Grade clusters
    df$cluster <- cut(
      df$grade,
      breaks = c(0, 1.5, 2.5, 3.5, 4.1),
      labels = c(
        "Very Good (≤1.5)",
        "Good (1.6–2.5)",
        "Average (2.6–3.5)",
        "Poor (3.6–4.0)"
      ),
      include.lowest = TRUE
    )
    
    ggplot(df, aes(y = exam_title, x = grade, color = cluster)) +
      geom_jitter(height = 0, size = 3, alpha = 1) +
      scale_color_manual(values = grade_colors) +
      labs(
        title = "All Student Grades per Exam",
        x = "Grade",
        y = "Exam",
        color = "Grade Cluster"
      ) +
      theme_minimal(base_size = 14) +
      theme(
        plot.title       = element_text(face = "bold", size = 18, hjust = 0.5),
        axis.title.x     = element_text(face = "bold", size = 16),
        axis.title.y     = element_text(face = "bold", size = 16),
        axis.text.x      = element_text(size = 14),
        axis.text.y      = element_text(size = 12),
        panel.grid.major = element_line(color = "grey60"),
        panel.grid.minor = element_line(color = "grey70"),
        legend.title     = element_text(face = "bold", size = 14),
        legend.text      = element_text(size = 12)
      )
  },
# DYNAMIC HEIGHT → enables vertical scrolling
# ============================================================================
  height = function() {
    
    df <- filtered_grades()
    n_exams <- length(unique(df$exam_title))
    
    # Minimum height + growth per exam
    max(400, n_exams * 35)
  })
  
  
# ============================================================================
# LEFT PLOT 2: Placeholder for One Exam Mode
# ============================================================================
# For now, this can be an empty plot that will be filled later with One Exam data
output$exam_plot2 <- renderPlot({
    # You can fill this later with a filtered plot
    NULL
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
  
  
  # ---- Disconnect when session ends ------------------------------------------
  session$onSessionEnded(function() {
    dbDisconnect(con)
  })
  
}
  