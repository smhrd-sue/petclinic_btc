<%@ tag trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="petclinic" tagdir="/WEB-INF/tags" %>

<%@ attribute name="pageName" required="true" %>
<%@ attribute name="customScript" required="false" fragment="true"%>

<!doctype html>
<html>
<petclinic:htmlHeader/>

<body>
<petclinic:bodyHeader menuName="${pageName}"/>

<div class="container-fluid">
    <div class="container xd-container">

        <jsp:doBody/>

<%
    String azureZone = "N/A (Local/Non-Azure)";
    try {
        // Azure Instance Metadata Service (IMDS) API 호출
        java.net.URL url = new java.net.URL("http://169.254.169.254/metadata/instance/compute/zone?api-version=2021-02-01&format=text");
        java.net.HttpURLConnection conn = (java.net.HttpURLConnection) url.openConnection();
        conn.setRequestMethod("GET");
        conn.setRequestProperty("Metadata", "true"); // Azure 필수 헤더
        conn.setConnectTimeout(1000);
        conn.setReadTimeout(1000);

        if (conn.getResponseCode() == 200) {
            java.util.Scanner s = new java.util.Scanner(conn.getInputStream(), "UTF-8").useDelimiter("\\A");
            azureZone = s.hasNext() ? s.next() : "Unknown";
        }
    } catch (Exception e) {
        azureZone = "Error or Non-Azure: " + e.getMessage();
    }
%>
<%
    String dbHost = "Unknown";
    try {
        // Spring의 ApplicationContext에서 DataSource 빈을 직접 가져옵니다.
        org.springframework.web.context.WebApplicationContext context = 
            org.springframework.web.context.support.WebApplicationContextUtils.getWebApplicationContext(application);
        javax.sql.DataSource ds = (javax.sql.DataSource) context.getBean(javax.sql.DataSource.class);
        
        try (java.sql.Connection conn = ds.getConnection();
             java.sql.Statement stmt = conn.createStatement();
             java.sql.ResultSet rs = stmt.executeQuery("SELECT @@hostname")) {
            if (rs.next()) {
                dbHost = rs.getString(1);
            }
        }
    } catch (Exception e) {
        dbHost = "Error: " + e.getMessage();
    }
%>


<div style="margin-top: 20px; padding: 15px; border: 1px solid #ccc; background-color: #f9f9f9; border-radius: 5px;">
    <h4 style="color: #007bff;"> Server Deployment Info</h4>
    <p><strong>Host Name:</strong> <%= java.net.InetAddress.getLocalHost().getHostName() %></p>
    <p><strong>Server IP:</strong> <%= java.net.InetAddress.getLocalHost().getHostAddress() %></p>
    <p><strong>LB Header (X-Forwarded-For):</strong> ${header["x-forwarded-for"]}</p>
    <p><strong>Azure Availability Zone:</strong> <%= azureZone %></p>
    <p><strong>DBHost:</strong> <%= dbHost %></p>
</div>
        <petclinic:pivotal/>
    </div>
</div>

<petclinic:footer/>
<jsp:invoke fragment="customScript" />

</body>

</html>
