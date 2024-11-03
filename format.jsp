<%@ page language="java" contentType="text/plain; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.io.*,java.util.*" %>
<%
    String code = request.getParameter("code");
    if (code == null || code.trim().isEmpty()) {
        out.println("Error: No code provided");
        return;
    }

    //create temp dir
    String tmpDir = application.getRealPath("/") + "tmp/";
    new File(tmpDir).mkdir();
    String inFile = tmpDir + "input.c";
    String outFile = tmpDir + "output.c";

    try {
        //write code to file
        FileWriter writer = new FileWriter(inFile);
        writer.write(code);
        writer.close();

        Process format = Runtime.getRuntime().exec(new String[]{
            "clang-format",
            "-style=LLVM",//LLVM
            inFile,
            "-i"
        });
        format.waitFor();

        //read formatted code
        BufferedReader reader = new BufferedReader(new FileReader(inFile));
        StringBuilder formatted = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            formatted.append(line).append("\n");
        }
        reader.close();

        out.println(formatted.toString());

    } catch (Exception e) {
        out.println("Error: " + e.getMessage());
    } finally {
        //clean up
        new File(inFile).delete();
        new File(outFile).delete();
    }
%>