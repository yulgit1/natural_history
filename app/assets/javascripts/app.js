document.addEventListener("turbolinks:load", function() {
    //console.log('It works on each visit!');
    $(".fancybox").fancybox();
});

function get_field() {
    var id = document.getElementById('id').value;
    var field = document.getElementById('field').value;
    if (id.length > 0 && field.length > 0) {
        get_field_ajax(id, field);
    }
}

function get_field_ajax(id,field) {

    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
            var output = "<p><b>Lookup:</b></p><p>"+this.responseText+"</p>";
            document.getElementById("field_contents").innerHTML = output;
        }
    };
    xhttp.open("GET","solr_lookup?id="+id+"&field="+field,true);
    xhttp.send();
}