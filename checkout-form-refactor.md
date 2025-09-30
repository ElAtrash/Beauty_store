first section:
**Address and delivery method ▼**

- **City** - Beirut (dropdown like we have now but set Beirut as a default)
- **Delivery method** - keep our radio buttons (but make pickup from store as default)
- next field will depend on delivery type since previous default is 'pickup from store' this field by default will be:

1. **Pickup point** for now we will have a placeholder Beaty Store and a random address in Beirut and a clickable 'details ->' that will open a modal (we will use the same modal styles we had for auth and cart modals.)that will show store details:
   Store name
   address
   cost — free
   delivery date — today
   Working hours
   Shelf life (the time the customer have to pickup the order)
   Contact phone number
   Coordinates
   small note How to get there.
2. if courier is picked from previous field a modal should open titled Delivery address. under we will place picked city from first field and there we put the fields (same style as in the form) we have for address_line_1, address_line_2, landmarks and delivery_notes and 'Bring it here' button. when submitted modal should close and the form should update the field from **Pickup point** to **Address** - we put the address the user submitted in the modal with a 'Change' button is case they misspelled the address or want to change it.

- **Delivery date and time** we don't have this field yet. if delivery by courier was picked It should allow the user to pick the day and time range they want the order to be delivered starting from the next day of order placement and in the span of 5 days. and then time range options like 9:00-12:00, 12:00-15:00 and so on until 21:00-23:00. When pickup point was chosen it will have something like 'Pick up your order between "today's date(month and day)" and "today's date + 2 days" inclusive.'

second section:
**Recipient ▼**

- Contacts - here we put our current phone and email fields we have one under another.
- Personal data - here we put First name and Last name fields

third section:
**Payment method ▼**
here will go out :payment_method radio button field other options we'll implement as part of checkout plan later.

Place order button stay unchanged as well as order summary section on the right side.
