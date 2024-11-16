<%@ page language="java" contentType="text/plain; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.io.*,java.util.*" %>
<%
    String code = request.getParameter("code");
    String lang = request.getParameter("lang");
    
    if (code == null || code.trim().isEmpty()) {
        out.println("Error: No code provided");
        return;
    }

    String sessionId = request.getSession().getId();
    String tmpDir = application.getRealPath("/") + "tmp/" + sessionId + "/";
    File tmpDirFile = new File(tmpDir);
    if (!tmpDirFile.exists()) {
        if (!tmpDirFile.mkdirs()) {
            out.println("Error: Failed to create temporary directory");
            return;
        }
    }

    String sourceFile = tmpDir + "program." + (lang.equals("cpp") ? "cpp" : "c");
    String outputFile = tmpDir + "program.out";
    String valgrindLog = tmpDir + "valgrind.log";

    try {
        File srcFile = new File(sourceFile);
        FileWriter writer = new FileWriter(srcFile);
        writer.write(code);
        writer.close();

        String compiler = lang.equals("cpp") ? "g++" : "gcc";
        String standardOption = lang.equals("cpp") ? "-std=c++20" : "-std=c11";

        Process compile = Runtime.getRuntime().exec(new String[]{
            compiler,
            "-g",
            standardOption,
            sourceFile,
            "-o",
            outputFile
        });

        BufferedReader errorReader = new BufferedReader(new InputStreamReader(compile.getErrorStream()));
        StringBuilder errorOutput = new StringBuilder();
        String line;
        while ((line = errorReader.readLine()) != null) {
            errorOutput.append(line).append("\n");
        }

        int exitCode = compile.waitFor();
        if (exitCode != 0) {
            out.println("Compilation Error:\n" + errorOutput.toString());
            return;
        }

        Process valgrind = Runtime.getRuntime().exec(new String[]{
            "valgrind",
            "--tool=memcheck",
            "--leak-check=full",
            "--show-leak-kinds=all",
            "--track-origins=yes",
            "--log-file=" + valgrindLog,
            outputFile
        });

        valgrind.waitFor();

        BufferedReader logReader = new BufferedReader(new FileReader(valgrindLog));
        StringBuilder report = new StringBuilder();
        while ((line = logReader.readLine()) != null) {
            report.append(line).append("\n");
        }
        logReader.close();

        out.println("Memory Analysis Report:\n");
        out.println(report.toString());

    } catch (Exception e) {
        out.println("Error: " + e.getMessage());
        e.printStackTrace(new PrintWriter(out));
    } finally {

        new File(sourceFile).delete();
        new File(outputFile).delete();
        new File(valgrindLog).delete();
        new File(tmpDir).delete();
    }
%>