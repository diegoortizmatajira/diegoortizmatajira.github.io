---
title: "{{ replace .Name "-" " " | title }}" # Title of the blog post.
date: {{ .Date }} # Date of post creation.
description: "Article description." 
featured: true 
draft: true 
toc: false 
# menu: main
#featureImage: "/images/path/file.jpg" 
#thumbnail: "/images/path/thumbnail.png" 
#shareImage: "/images/path/share.png" 
codeMaxLines: 10 
codeLineNumbers: false 
figurePositionShow: true 
categories:
  - Technology
tags:
  - Tag_name1
  - Tag_name2
# comment: false # Disable comment if false.
---

**Insert Lead paragraph here.**