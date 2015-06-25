
body {
  padding-top: 5px;
}

header .inner {
  margin-left: 0px !important;
  padding: 0 30px;
}

td {
  padding-left: 5px;
}

p.css-vertical-text {
  color:#333;
  border:0px solid red;
  writing-mode:tb-rl;
  -webkit-transform:rotate(90deg);
  -moz-transform:rotate(90deg);
  -o-transform: rotate(90deg);
  white-space:nowrap;
  display:block;
  bottom:0;
  width:20px;
  height:20px;
  fo-nt-family: ‘Trebuchet MS’, Helvetica, sans-serif;
  font-size:24px;
  font-weight:normal;
}

.title{
  background: #cce4f3;
  position: relative;
  height: 37px;
  line-height: 37px;
  border: 1px solid #95c6e3;
}

.titletext{
  color: #ed174c;
  font-size: 15px;
  margin: 0;
  padding: 0 0 0 15px;
  text-shadow: 1px 1px 1px #fff;
}

.dataCell {
  vertical-align:top;
  border: 1px solid #C0C0C0;
  height:200px; 
  border-top : 0px;
} 

@page {
  size:landscape;                    
  @top-center {content: element(header);}
}